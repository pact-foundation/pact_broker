require 'sequel'

module Sequel
  class Annotate
    # Append/replace the schema comment for all of the given files.
    # Attempts to guess the model for each file using a regexp match of
    # the file's content, if this doesn't work, you'll need to create
    # an instance manually and pass in the model and path. Example:
    # 
    #   Sequel::Annotate.annotate(Dir['models/*.rb'])
    def self.annotate(paths, options = {})
      Sequel.extension :inflector
      namespace = options[:namespace]

      paths.each do |path|
        text = File.read(path)

        next if text.match(/^#\s+sequel-annotate:\s+false$/i)

        name = nil
        if namespace == true
          constants = text.scan(/\bmodule ([^\s]+)|class ([^\s<]+)\s*</).flatten.compact
          name = constants.join("::") if constants.any?
        elsif match = text.match(/class ([^\s<]+)\s*</)
          name = match[1]
          if namespace
            name = "#{namespace}::#{name}"
          end
        end

        if name
          klass = name.constantize
          if klass.ancestors.include?(Sequel::Model)
            new(klass).annotate(path, options)
          end
        end
      end
    end

    # The model to annotate
    attr_reader :model

    # Store the model to annotate
    def initialize(model)
      @model = model
    end

    # Append the schema comment (or replace it if one already exists) to
    # the file at the given path.
    def annotate(path, options = {})
      return if skip_model?

      orig = current = File.read(path).rstrip

      if options[:position] == :before
        if current =~ /\A((?:^\s*$|^#\s*(?:frozen_string_literal|coding|encoding|warn_indent|warn_past_scope)[^\n]*\s*)*)/m
          magic_comments = $1
          current.slice!(0, magic_comments.length)
        end

        current = current.gsub(/\A#\sTable[^\n\r]+\r?\n(?:#[^\n\r]*\r?\n)*/m, '').lstrip
        current = "#{magic_comments}#{schema_comment(options)}#{$/}#{$/}#{current}"
      else
        if m = current.reverse.match(/#{"#{$/}# Table: ".reverse}/m)
          offset = current.length - m.end(0) + 1
          unless current[offset..-1].match(/^[^#]/)
            # If Table: comment exists, and there are no
            # uncommented lines between it and the end of the file
            # then replace current comment instead of appending it
            current = current[0...offset].rstrip
          end
        end
        current += "#{$/}#{$/}#{schema_comment(options)}"
      end

      if orig != current
        File.open(path, "wb") do |f|
          f.puts current
        end
      end
    end

    # The schema comment to use for this model.  
    # For all databases, includes columns, indexes, and foreign
    # key constraints in this table referencing other tables.
    # On PostgreSQL, also includes check constraints, triggers,
    # and foreign key constraints in other tables referencing this table.
    #
    # Options:
    # :border :: Include a border above and below the comment.
    # :indexes :: Do not include indexes in annotation if set to +false+.
    # :foreign_keys :: Do not include foreign key constraints in annotation if set to +false+.
    #
    # PostgreSQL-specific options:
    # :constraints :: Do not include check constraints if set to +false+.
    # :references :: Do not include foreign key constraints in other tables referencing
    #                this table if set to +false+.
    # :triggers :: Do not include triggers in annotation if set to +false+.
    def schema_comment(options = {})
      return "" if skip_model?

      output = []
      output << "# Table: #{model.dataset.with_quote_identifiers(false).literal(model.table_name)}"

      meth = :"_schema_comment_#{model.db.database_type}"
      if respond_to?(meth, true)
        send(meth, output, options)
      else
        schema_comment_columns(output)
        schema_comment_indexes(output) unless options[:indexes] == false
        schema_comment_foreign_keys(output) unless options[:foreign_keys] == false
      end


      # Add beginning and end to the table if specified
      if options[:border]
        border = "# #{'-' * (output.map(&:size).max - 2)}"
        output.push(border)
        output.insert(1, border)
      end

      output.join($/)
    end

    private

    # Returns an array of strings for each array of array, such that
    # each string is aligned and commented appropriately.  Example:
    #
    #   align([['abcdef', '1'], ['g', '123456']])
    #   # => ["#  abcdef  1", "#  g       123456"]
    def align(rows)
      cols = rows.first.length
      lengths = [0] * cols

      cols.times do |i|
        rows.each do |r|
          lengths[i] = r[i].length if r[i] && r[i].length > lengths[i]
        end
      end

      rows.map do |r|
        "#  #{r.zip(lengths).map{|c, l| c.to_s.ljust(l).gsub("\n", "\n#    ")}.join(' | ')}".strip
      end
    end

    # Use the standard columns schema output, but use PostgreSQL specific
    # code for additional schema information.
    def _schema_comment_postgres(output, options = {})
      _table_comment_postgres(output, options)
      schema_comment_columns(output, options)
      oid = model.db.send(:regclass_oid, model.table_name)

      # These queries below are all based on the queries that psql
      # uses, captured using the -E option to psql.

      unless options[:indexes] == false
        rows = model.db.fetch(<<SQL, :oid=>oid).all
SELECT c2.relname, i.indisprimary, i.indisunique, pg_catalog.pg_get_indexdef(i.indexrelid, 0, true)
FROM pg_catalog.pg_class c, pg_catalog.pg_class c2, pg_catalog.pg_index i
  LEFT JOIN pg_catalog.pg_constraint con ON (conrelid = i.indrelid AND conindid = i.indexrelid AND contype IN ('p','u','x'))
WHERE c.oid = :oid AND c.oid = i.indrelid AND i.indexrelid = c2.oid AND indisvalid
ORDER BY i.indisprimary DESC, i.indisunique DESC, c2.relname;
SQL
        unless rows.empty?
          output << "# Indexes:"
          rows = rows.map do |r|
            [r[:relname], "#{"PRIMARY KEY " if r[:indisprimary]}#{"UNIQUE " if r[:indisunique] && !r[:indisprimary]}#{r[:pg_get_indexdef].match(/USING (.+)\z/m)[1]}"]
          end
          output.concat(align(rows))
        end
      end

      unless options[:constraints] == false
        rows = model.db.fetch(<<SQL, :oid=>oid).all
SELECT r.conname, pg_catalog.pg_get_constraintdef(r.oid, true)
FROM pg_catalog.pg_constraint r
WHERE r.conrelid = :oid AND r.contype = 'c'
ORDER BY 1;
SQL
        unless rows.empty?
          output << "# Check constraints:"
          rows = rows.map do |r|
            [r[:conname], r[:pg_get_constraintdef].match(/CHECK (.+)\z/m)[1]]
          end
          output.concat(align(rows))
        end
      end

      unless options[:foreign_keys] == false
        rows = model.db.fetch(<<SQL, :oid=>oid).all
SELECT conname,
  pg_catalog.pg_get_constraintdef(r.oid, true) as condef
FROM pg_catalog.pg_constraint r
WHERE r.conrelid = :oid AND r.contype = 'f' ORDER BY 1;
SQL
        unless rows.empty?
          output << "# Foreign key constraints:"
          rows = rows.map do |r|
            [r[:conname], r[:condef].match(/FOREIGN KEY (.+)\z/m)[1]]
          end
          output.concat(align(rows))
        end
      end

      unless options[:references] == false
        rows = model.db.fetch(<<SQL, :oid=>oid).all
SELECT conname, conrelid::pg_catalog.regclass::text,
  pg_catalog.pg_get_constraintdef(c.oid, true) as condef
FROM pg_catalog.pg_constraint c
WHERE c.confrelid = :oid AND c.contype = 'f' ORDER BY 2, 1;
SQL
        unless rows.empty?
          output << "# Referenced By:"
          rows = rows.map do |r|
            [r[:conrelid], r[:conname], r[:condef].match(/FOREIGN KEY (.+)\z/m)[1]]
          end
          output.concat(align(rows))
        end
      end

      unless options[:triggers] == false
        rows = model.db.fetch(<<SQL, :oid=>oid).all
SELECT t.tgname, pg_catalog.pg_get_triggerdef(t.oid, true), t.tgenabled, t.tgisinternal
FROM pg_catalog.pg_trigger t
WHERE t.tgrelid = :oid AND (NOT t.tgisinternal OR (t.tgisinternal AND t.tgenabled = 'D'))
ORDER BY 1;
SQL
        unless rows.empty?
          output << "# Triggers:"
          rows = rows.map do |r|
            [r[:tgname], r[:pg_get_triggerdef].match(/((?:BEFORE|AFTER) .+)\z/m)[1]]
          end
          output.concat(align(rows))
        end
      end
    end

    def _column_comments_postgres
      model.db.fetch(<<SQL, :oid=>model.db.send(:regclass_oid, model.table_name)).to_hash(:attname, :description)
SELECT a.attname, d.description
FROM pg_description d
JOIN pg_attribute a ON (d.objoid = a.attrelid AND d.objsubid = a.attnum)
WHERE d.objoid = :oid AND COALESCE(d.description, '') != '';
SQL
    end

    def _table_comment_postgres(output, options = {})
      return if options[:comments] == false

      if table_comment = model.db.fetch(<<SQL, :oid=>model.db.send(:regclass_oid, model.table_name)).single_value
SELECT obj_description(CAST(:oid AS regclass), 'pg_class') AS "comment" LIMIT 1;
SQL
        text = align([["Comment: #{table_comment}"]])
        text[0][1] = ''
        output.concat(text)
      end
    end

    # The standard column schema information to output.
    def schema_comment_columns(output, options = {})
      if cpk = model.primary_key.is_a?(Array)
        output << "# Primary Key: (#{model.primary_key.join(', ')})"
      end
      output << "# Columns:"

      meth = :"_column_comments_#{model.db.database_type}"
      column_comments = if options[:comments] != false && respond_to?(meth, true)
        send(meth)
      else
        {}
      end

      rows = model.columns.map do |col|
        sch = model.db_schema[col]
        parts = [
          col.to_s,
          sch[:db_domain_type] || sch[:db_type],
          "#{"PRIMARY KEY #{"AUTOINCREMENT " if sch[:auto_increment] && model.db.database_type != :postgres}" if sch[:primary_key] && !cpk}#{"NOT NULL " if sch[:allow_null] == false && !sch[:primary_key]}#{"DEFAULT #{sch[:default]}" if sch[:default]}#{"GENERATED BY DEFAULT AS IDENTITY" if sch[:auto_increment] && !sch[:default] && model.db.database_type == :postgres && model.db.server_version >= 100000}",
        ]
        parts << (column_comments[col.to_s] || '') unless column_comments.empty?
        parts
      end
      output.concat(align(rows))
    end

    # The standard index information to output.
    def schema_comment_indexes(output)
      unless (indexes = model.db.indexes(model.table_name)).empty?
        output << "# Indexes:"
        rows = indexes.map do |name, metadata|
          [name.to_s, "#{'UNIQUE ' if metadata[:unique]}(#{metadata[:columns].join(', ')})"]
        end
        output.concat(align(rows).sort)
      end
    end

    # The standard foreign key information to output.
    def schema_comment_foreign_keys(output)
      unless (fks = model.db.foreign_key_list(model.table_name)).empty?
        output << "# Foreign key constraints:"
        rows = fks.map do |fk|
          ["(#{fk[:columns].join(', ')}) REFERENCES #{fk[:table]}#{"(#{fk[:key].join(', ')})" if fk[:key]}"]
        end
        output.concat(align(rows).sort)
      end
    end

    # Whether we should skip annotations for the model.
    # True if the model selects from a dataset.
    def skip_model?
      model.dataset.joined_dataset? || model.dataset.first_source_table.is_a?(Dataset)
    rescue Sequel::Error
      true
    end
  end
end

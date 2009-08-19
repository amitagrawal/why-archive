class Sequel::SQLite::Dataset
  def table_name
    @opts[:from]
  end
  def to_html
    set = self
    Web.Bit {
      h1 "The #{set.table_name} Table"
      set.each do |item|
        div.entry { 
          p do
            strong do
              a(:href => '#') { item[:Title] }
              puts " Table::Item"
            end
          end
          p "at #{item[:created]}"
          p { puts item[:Editbox] }
        }
      end
    }
  end
end
class Sequel::Dataset
  def only(id)
    first(:where => ['id = ?', id])
  end
  def limit(num)
    dup_merge(:limit => num)
  end
  def recent(num)
    order("Created DESC").limit(num)
  end
  def save(data)
    @db.save(@opts[:from], data)
  end
end
module HacketyDbMixin
  SPECIAL_FIELDS = ['id', 'created', 'updated']
  def tables
    execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name").
      map { |name,| name if name !~ /^HACKETY_/ }.compact
  end
  def save(table, obj)
    table = table.to_s
    fields = get_fields(table)
    if fields.empty?
      startup(table, obj.keys)
    else
      missing = obj.keys - fields
      unless missing.empty?
        missing.each do |name|
          add_column(table, name)
        end
      end
    end
    if obj['id']
      from(table).only(obj['id']).update(obj.merge(:updated => Time.now))
      puts "Updated entry in the #{table} table"
    else
      from(table).insert(obj.merge(:created => Time.now, :updated => Time.now))
      puts "Saved new entry to the #{table} table"
    end
  end
  def init
    unless table_exists? "HACKETY_PREFS"
      create_table "HACKETY_PREFS" do
        primary_key :id, :integer
        column :name, :text
        column :value, :text
        index :name
      end
    end
    HacketyHack.load_prefs
    unless table_exists? "HACKETY_SHARES"
      create_table "HACKETY_SHARES" do
        primary_key :id, :integer
        column :title, :text
        column :klass, :text
        column :active, :integer
        index :title
      end
    end
    HacketyHack.load_shares
  end
  def startup(table, fields)
    SPECIAL_FIELDS.each do |x|
      fields.each do |y|
        raise ArgumentError, "Can't have a field called #{y}!" if y.downcase == x
      end
    end
    create_table table do
      primary_key :id, :integer
      column :created, :datetime
      column :updated, :datetime
      fields.each do |name|
        column name, :text
        if [:title, :name].include? name
          index name
        end
      end
    end
    true
  rescue SQLite3::SQLException
    false
  end
  def drop_table(table)
    raise ArgumentError, "Table name must be letters, numbers, underscores only." if table !~ /^\w+$/
    execute("DROP TABLE #{table}")
  end
  def get_fields(table)
    raise ArgumentError, "Table name must be letters, numbers, underscores only." if table !~ /^\w+$/
    execute("PRAGMA table_info(#{table})").map { |id, name,| name }
  end
  def add_column(table, column)
    raise ArgumentError, "Table name must be letters, numbers, underscores only." if table !~ /^\w+$/
    execute("ALTER TABLE #{table} ADD COLUMN #{Sequel::Schema.column_definition(:name => column, :type => :text)}")
  end
end
def Table(t)
  raise ArgumentError, "Table name must be letters, numbers, underscores only.  No spaces!" if t !~ /^\w+$/
  if HacketyHack.check_share(t, 'Table')
    Web.table(t)
  else
    HacketyDB[t]
  end
end

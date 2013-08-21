require 'spec_helper'

describe 'concept' do
  class MyDocument < ActiveRecord::Base
  end

  class MyDocumentStore
    class << self
      def new_uuid
	SecureRandom.uuid
      end

      def all
	MyDocument.all
      end

      def save(hash)
	id = (hash[:id] ||= new_uuid)
	if rec = MyDocument.exists?(id: id)
	else
	  destruct_hash(id, hash).each do |attrs|
	    MyDocument.create(attrs)
	  end
	end
      end

      def find(id)
	construct_hash MyDocument.where(agg: id.to_s).map(&:attributes).map(&:symbolize_keys)
      end

      def destruct_hash(uuid, hash)
	first_row = { id: uuid, agg: uuid, attrs: { }}
	[first_row].tap do |acc|
	  hash.each do |k, v|
	    case v
	    when Hash
	      destruct_nested_hash(uuid, acc, k.to_s, v)
	    else
	      first_row[:attrs][k] = v
	    end
	  end
	end
      end

      def destruct_nested_hash(uuid , acc, path, hash)
	acc<< (row = {agg: uuid, path: path, attrs: {}})
	hash.each do |k, v|
	  case v
	  when Hash
	    destruct_nested_hash(uuid, acc, "#{path}.#{k}", v)
	  else
	    row[:attrs][k] = v
	    end
	end
      end

      def construct_hash(rows)
	{}.tap do |result|
	  rows
	  .sort_by {|h| h[:path] || '' }
	  .each do |row|
	    if row[:path].nil?
	      result
	      .merge!(id: row[:id])
	      .merge!(row[:attrs].symbolize_keys)
	    else
	      parent = result

	      path = row[:path]
	      .split('.')
	      .map(&:to_sym)

	      key = path.delete_at(-1)
	      while k = path.shift
		parent = parent[k]
	      end
	      parent[key] = row[:attrs].symbolize_keys
	    end
	  end
	end
      end
    end
  end

  before(:all) do
    conn = ActiveRecord::Base.connection

    conn.execute <<-SQL
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "hstore";
DROP TABLE my_documents;
CREATE TABLE my_documents (
  id uuid primary key default uuid_generate_v4(),
  agg uuid,
  path varchar,
  attrs hstore);
    SQL
  end

  example do
    doc = MyDocument.create(attrs: {a: 'a', b: 'b'})
    doc.attrs.should == {a: 'a', b: 'b'}
  end

  example do
    id = SecureRandom.uuid
    attrs = {id: id.to_s, a: 'a', b: 'b', c: {d: 'e', f: {g: 'h'}}}
    MyDocumentStore.save(attrs)
    MyDocumentStore.find(id).should == attrs

    MyDocument
    .where(path: 'c.f')
    .where("attrs-> 'g' = 'h'")
    .should_not be_empty
  end

  it '#destruct_hash' do
    res = MyDocumentStore
    .destruct_hash('uid',
		   a: 'b', c: { d: 'e', f: { g: 'h' }})

    res.should == [
      {id: 'uid', agg: 'uid', attrs: {a: 'b'}},
      {agg: 'uid', path: 'c', attrs: {d: 'e'}},
      {agg: 'uid', path: 'c.f', attrs: {g: 'h'}}
    ]
  end

  it '#construct_hash' do
    res = MyDocumentStore.construct_hash([
      {agg: 'uid', path: 'c', attrs: {d: 'e'}},
      {agg: 'uid', path: 'c.f', attrs: {g: 'h'}},
      {id: 'uid', agg: 'uid', attrs: {a: 'b'}}
    ])
    res.should == {id: 'uid', a: 'b', c: { d: 'e', f: {g: 'h'}}}
  end
end

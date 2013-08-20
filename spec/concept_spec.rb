require 'spec_helper'

describe 'concept' do
  class MyDocument < ActiveRecord::Base
  end

  class MyDocumentStore
    class << self
      def new_uuid
        nil
      end

      def save(hash)
        hash[:id] ||= new_uuid
        destruct_hash(hash[:id], hash)
      end

      def destruct_hash(uuid, hash)
        first_row = { id: uuid, agg: uuid, attrs: { }}
        acc = [first_row]
        hash.each do |k, v|
          case v
          when Hash
            destruct_nested_hash(uuid, acc, k.to_s, v)
          else
            first_row[:attrs][k] = v
          end
        end
        acc
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
    attrs = {a: 'a', b: 'b'}
    MyDocumentStore.save(attrs)
    # MyDocumentStore.all
    pending
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
    pending
    res = MyDocumentStore.destruct_hash([
      {id: 'uid', agg: 'uid', attrs: {a: 'b'}},
      {agg: 'uid', path: 'c', attrs: {d: 'e'}},
      {agg: 'uid', path: 'c.f', attrs: {g: 'h'}}
    ])
    res.should =~ {id: 'uid', a: 'b', c: { d: 'e', f: {g: 'h'}}}
  end
end

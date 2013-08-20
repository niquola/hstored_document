# HstoredDocument

* Allow store/retrieve deep ruby hash into postgresql table using hstore field.
* Allow efficient search and indexing by this fields

## Installation

Add this line to your application's Gemfile:

    gem 'hstored_document'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hstored_document

## Usage

create table mydocs (id uuid, attributes hstore);

```ruby
class MyDocStorage < HstoredDocument
end

id = UUID.generate
doc = {id: id, prop1: 'val1', prop2: [1, 2, 3], prop3: [{nprop: 'nval'}]}

store = MyDocStorage

store.store(doc)
store.find(id).should == doc

store.where('doc.prop2' => 3, prop1: 'val1')
store.where('doc.prop3.nprop' => 'nval')

store.store(doc.merge(propr1: 'changed1'))
store.find(id)[:prop1].should == 'changed1'
store.delete(id)

```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

# DbContext

This gem is an extension to factory_girl gem. It is supposed to help write more readble test code and improve test performance with bulk insertion when neccessary.

Without db-context, to create an author with three associate posts, each post has three comments
  
    author = FactoryGirl.create :author
    
    3.times.map do
      FactoryGirl.create :post, author: author
    end
    .each do |post|
      3.times{ FactoryGirl.create :comment, post: post }
    end    
    
With db-context, we can do the same with much less and readable code
  
    1.Author.has_3_posts(:assoc).each_has_3_comments

## Installation

Add this line to your application's Gemfile:

    gem 'db_context'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install db_context

## Usage

### Extensions to Array <a name='array'></a>

####\#belongs\_to\_{association_name}(associate\_objects, *directives, &block)

    class Post
      belongs_to :writer, class_name: 'Author', foreign_key: 'author_id'
    end
    class Author
      has_many :posts
    end
    
    6.Posts.belongs_to_writer 3.Authors # 6 posts will be allocated equally for 3 authors
    
    # the associate name can be omitted from the method call if it can be elicited from associated class
    class Post
      belongs_to :author
    end
    
    6.Posts.belongs_to 3.Authors # :author association can be elicited from Author class
    
    # if the items cannot be allocated equally to associated objects, extra objects are allocated randomly
    
    8.Posts.belongs_to 3.Authors # each author gets 2 posts, 2 remaining posts are allocated randomly
    
    # associate objects can be a single object instead of an array of associate objects
    
    3.Posts.belongs_to FactoryGirl.create :author
    
    # to return the associated objects instead of the caller, use :assoc directive
    
    6.Posts.belongs_to(3.Authors, :assoc) # the array of authors will be returned instead of the array of posts
    
    # with a code block, the block is executed before each pair of object are saved
    
    6.Posts.belongs_to 3.Authors do |post, author|
      post.description = "This post is written by #{author.name}"
    end
    
    # when the objects are saved to set up the association, validations are ignored
    
    6.Posts.belongs_to 3.Authors do |post, author|
      author.email = "" # this will not cause an validation failure even though email is required
    end

####\#make_{association_name}(*directives, options = {}, &block)
    
    # Factory_girl will always be used to insert associate objects
    3.Posts.make_author # create one author for each of three posts
    
    # With factory
    3.Posts.make_author(factory: :valid_author) # create authors with :valid_author factory
    
    # With factory, trait and overiden attributes
    3.Posts.make_author(factory: [:author, :valid, first_name: 'Josh', last_name: 'Smith' ])
    
    # With a block, the block will be executed just before objects are saved
    3.Posts.make_author do |post, author_attributes|
      author_attributes[:last_name] = 'Smith'
      post.description = "Writen by #{author_attributes[:first_name]}"
    end
    
    # With a block, validations will be ignored when existing objects are saved
    3.Posts.make_author do |post, author_attributes|
      author_attributes[:last_name] = '' # causes validation failure if last_name is required
      post.description = "" # not cause validation failure even if description is required
    end
    
    # To return the associate objects instead of the caller, use :assoc directive
    3.Posts.make_author(:assoc) # array of newly created authors will be returned    

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

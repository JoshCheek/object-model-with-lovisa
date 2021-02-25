How Ruby works (Josh's Object model)
====================================

Explains how I think about Ruby. This will be slightly simplified to make it
more consistent and easier to understand. It will be useful for understanding
95% of the Ruby you will see.

If anything doesn't jive with your understanding, ask and I can explain it if
it doesn't muddy the model too much.


The 3 important structures
--------------------------

There are 3 important structures for understanding Ruby.
You can think of them however you like, if you know C, they are implemented
as C structs, but if you don't know C, then you can think about them as hashes.


### Structure 1: Bindings

Bindings are the context execute is executed in.  They have:

* `self` the `VALUE` of the object we are implicitly in
  * instance variables come from here, and are set here
  * methods without receivers are called on this object
* `local_variables` hash table whose keys are names and values are objects
* `environment` another binding where we can look up additional local variables
  * eg this is why a block can see variables defined outside of it

These are stored in the callstack. When you call a method on an object, you
push a new one onto the stack to evaluate the method in. When that method returns
it does so by popping that method off the callstack.

So in general, any time `self` or `local_variables` change, you can know that
the callstack pushed or popped a binding.

There are other things here, too, which we'll omit, such as whether we're
public or private, where `def` keyword should put methods, and other stuff,
but the 3 things above are the important ones.
Here is an old definition you can look at if you want to dive a bit deeper:
https://github.com/ruby/ruby/blob/65a5162550f58047974793cdc8067a970b2435c0/eval.c#L415-L429

Interact:
* play the self game?
* bin/spelunk examples/cook_spaghetti.rb

### Structure 2: Objects

Objects store related data in their instance variables, and know which methods
operate on that data by keeping track of their class.  They have:

* `class` the class that contains the methods that operate on this object's instance variables
* `instance_variables` a hash table whose keys are symbols and values are Ruby objects (called a "symbol table" in the C code)

Note that this definition can get really fuzzy when you dig into the C.
For all of your objects, this will be true, but for objects in core Ruby,
there may be deviations. For example, string data isn't stored in instance variables,
and numbers are represented as values within their memory address.

**How do I know I have an object?**

* If you can assign it to a variable, it is an object
* If you can call a method on it, it is an object

Note that Methods are **always** called on ojbects.

You can see an old example of how Ruby defined objects here: https://github.com/ruby/ruby/blob/65a5162550f58047974793cdc8067a970b2435c0/ruby.h#L218-LL226
(using an old one because more recent ones are difficult to read due toi changes
that have been made for optimization purposes)

Interact:
* Show that ivars get set and looked up on this object?

### Structure 3: Classes

Classes store the methods that operate on their instances.
Their "instances" are objects they are the `class` of.
They have:

* `methods` a hash (symbol table) whose keys are method names.
* `superclass` another class containing inherited methods.
* `constants` a hash whose keys are constant names.
* Classes are also objects, so they have the things that objects have

You can see an old definition of classes here: https://github.com/ruby/ruby/blob/65a5162550f58047974793cdc8067a970b2435c0/ruby.h#L228-L233

* Method lookup always starts at the receiver (except when using the `super` keyword)
* Method lookup goes like this:
  * `object.class.superclass.superclass.superclass ...`
  * You can think of it like a linked list, which might do: `list.head.link.link.link ...`

Interact:
* https://github.com/JoshCheek/object_model_8th_light/blob/8346d880c75259f29693baba1ed2aa87c08b9084/challenges/super.rb
* https://github.com/JoshCheek/object_model_8th_light/blob/8346d880c75259f29693baba1ed2aa87c08b9084/challenges/super2.rb

What next?
----------

If we make it this far, we have a lot of options:
* Talk about how we use this structure to provide Singleton Classes
* Talk about modules
* Show that there is always a self (self game?)
* Show stack explorer https://github.com/JoshCheek/object-model-with-lovisa
  on `examples/linked_list.rb` or `examples/medusa.rb`
* Show the obj model challenges (https://github.com/JoshCheek/object_model_8th_light/tree/8346d880c75259f29693baba1ed2aa87c08b9084/challenges)


<!-- README.md is generated from README.Rmd. Please edit that file -->

# mongooser

<!-- badges: start -->

<!-- badges: end -->

\[WIP / DO NOT USE IN PRODUCTION\]

The goal of mongooser is to port [mongoosejs]() to R, for a more,
predictable use of MongoDB in a production context.

## Installation

You can install the development version of mongooser like so:

``` r
remotes::install_github("thinkr-open/mongooser")
```

### What’s wrong with `{mongolite}`?

Nothing, `{mongooser}` is actually built on top of it.

### Ok, so why?

An issue with MongoDB is that it doesn’t enforce any kind of schema, and
R isn’t very well equiped to handle unstructured data.

Also, given that it’s unstructured and does the type conversion for you,
you can get unexpected results when using MongoDB with R.

And on top of that, human tend to be a little bit lazy, and if the db
allows them to insert random unstructured elements in the db, well,
they’ll do it, and then some data engineer will cry and scream to
scrap and restructure the data to be usable.

Here is a simple example:

``` r
con <- mongolite::mongo()
con$insert(data.frame(x = 1))
#> List of 5
#>  $ nInserted  : num 1
#>  $ nMatched   : num 0
#>  $ nRemoved   : num 0
#>  $ nUpserted  : num 0
#>  $ writeErrors: list()
con$insert(data.frame(x = "this"))
#> List of 5
#>  $ nInserted  : num 1
#>  $ nMatched   : num 0
#>  $ nRemoved   : num 0
#>  $ nUpserted  : num 0
#>  $ writeErrors: list()
res <- con$find()
class(res$x)
#> [1] "character"
res <- con$find('{"x":1}')
class(res$x)
#> [1] "numeric"
res <- con$find('{"x":"this"}')
class(res$x)
#> [1] "character"
```

As MongoDB & `{mongolite}` doesn’t inforce any kind of type on
read/write, it can be hard to rely on the output.

It’s even more complex when you start having nested elements.

``` r
con$drop()
con <- mongolite::mongo()
con$insert(
  list(
    y = data.frame(x = 1)
  )
)
#> List of 6
#>  $ nInserted  : int 1
#>  $ nMatched   : int 0
#>  $ nModified  : int 0
#>  $ nRemoved   : int 0
#>  $ nUpserted  : int 0
#>  $ writeErrors: list()
# You'd expect to have a list with a data.frame
con$find()
#>   y
#> 1 1
con$insert(
  list(
    z = data.frame(x = 1)
  )
)
#> List of 6
#>  $ nInserted  : int 1
#>  $ nMatched   : int 0
#>  $ nModified  : int 0
#>  $ nRemoved   : int 0
#>  $ nUpserted  : int 0
#>  $ writeErrors: list()
# You'd expect to have 2 lists with a data.frame
con$find()
#>      y    z
#> 1    1 NULL
#> 2 NULL    1

# You can also do
it <- con$iterate()
while (!is.null(x <- it$one())) {
  print(x)
}
#> $y
#> $y[[1]]
#> $y[[1]]$x
#> [1] 1
#> 
#> 
#> 
#> $z
#> $z[[1]]
#> $z[[1]]$x
#> [1] 1
# But that's still not exactly what you'd want
```

`{mongooser}` tries to solve that issue by porting [mongoose.js]() to R.

## Here is an example

    docker run -d -p 2811:27017 mongo:3.4

``` r
library(mongooser)
# New instance of Mongoose
mongoose <- Mongoose$new()

# # Connect to the DB
mongoose$connect(
  url = "mongodb://localhost:2811"
)

# This create an object that will
# query / write to the `name`
# collection (here Cat)
Cat <- mongoose$model(
  name = "Cat",
  schema = list(
    name = list(
      type = "character"
    )
  )
)
# You can drop everything from the collection if you want
Cat$drop()

# Cat$new() will create a new document object,
# You __need__ to pass to the object data that
# match the schema defined in the model

# This should fail => bad type
kitty <- Cat$new(
  list(
    name = 1234
  )
)
#> Error: [Bad Type] name does not inherits from character
# This should fail => undefined schema entry
kitty <- Cat$new(
  list(
    name = 1234,
    weight = 12
  )
)
#> Error: [Undefined Entry] All elements should be defined in the data model

# This will work
fluffy <- Cat$new(
  list(
    name = "Fluffy"
  )
)

# Expected output => An empty list
Cat$find()
#> list()

# Saving the fluffy doc
fluffy$save()
#> List of 6
#>  $ nInserted  : int 1
#>  $ nMatched   : int 0
#>  $ nModified  : int 0
#>  $ nRemoved   : int 0
#>  $ nUpserted  : int 0
#>  $ writeErrors: list()

# Expected output =>
# A list of length one, and the first element is
# $name
# [1] "Fluffy"
Cat$find()
#> [[1]]
#> [[1]]$name
#> [1] "Fluffy"

# Let's now create a new document
minette <- Cat$new(
  list(
    name = "minette"
  )
)
# Save it
minette$save()
#> List of 6
#>  $ nInserted  : int 1
#>  $ nMatched   : int 0
#>  $ nModified  : int 0
#>  $ nRemoved   : int 0
#>  $ nUpserted  : int 0
#>  $ writeErrors: list()

# Expected output =>
# A list of length two, with both elements being
# $name
# [1] "" <- character string
Cat$find()
#> [[1]]
#> [[1]]$name
#> [1] "Fluffy"
#> 
#> 
#> [[2]]
#> [[2]]$name
#> [1] "minette"

# Let's now compare to what you'd get with
# base mongolite
con <- mongolite::mongo(collection = "Cat")
con$drop()
con$insert(
  list(
    name = "Fluffy"
  )
)
#> List of 6
#>  $ nInserted  : int 1
#>  $ nMatched   : int 0
#>  $ nModified  : int 0
#>  $ nRemoved   : int 0
#>  $ nUpserted  : int 0
#>  $ writeErrors: list()
con$find()
#>     name
#> 1 Fluffy
con$insert(
  list(
    name = "minette"
  )
)
#> List of 6
#>  $ nInserted  : int 1
#>  $ nMatched   : int 0
#>  $ nModified  : int 0
#>  $ nRemoved   : int 0
#>  $ nUpserted  : int 0
#>  $ writeErrors: list()
con$find()
#>      name
#> 1  Fluffy
#> 2 minette
```

Here for a more complex example with a dataframe inside

``` r
Cat <- mongoose$model(
  name = "Cat",
  schema = list(
    name = list(
      type = "character"
    ),
    food = list(
      type = "data.frame"
    )
  )
)

Cat$drop()

fluffy <- Cat$new(
  list(
    name = "fluffy",
    food = data.frame(
      date = "2022-02-12",
      type = "fish"
    )
  )
)
fluffy$save()
#> List of 6
#>  $ nInserted  : int 1
#>  $ nMatched   : int 0
#>  $ nModified  : int 0
#>  $ nRemoved   : int 0
#>  $ nUpserted  : int 0
#>  $ writeErrors: list()

# Expected output => list of length one,
# with one character string in "name" and
# one data frame in "food"
Cat$find()
#> [[1]]
#> [[1]]$name
#> [1] "fluffy"
#> 
#> [[1]]$food
#>         date type
#> 1 2022-02-12 fish

minette <- Cat$new(
  list(
    name = "minette",
    food = data.frame(
      date = "2022-02-12",
      type = "cake"
    )
  )
)
minette$save()
#> List of 6
#>  $ nInserted  : int 1
#>  $ nMatched   : int 0
#>  $ nModified  : int 0
#>  $ nRemoved   : int 0
#>  $ nUpserted  : int 0
#>  $ writeErrors: list()

# Expected output => list of length two,
# each element has
# one character string in "name" and
# one data frame in "food"
Cat$find()
#> [[1]]
#> [[1]]$name
#> [1] "fluffy"
#> 
#> [[1]]$food
#>         date type
#> 1 2022-02-12 fish
#> 
#> 
#> [[2]]
#> [[2]]$name
#> [1] "minette"
#> 
#> [[2]]$food
#>         date type
#> 1 2022-02-12 cake

# Let's now compare to mongolite default behavior
con <- mongolite::mongo(collection = "Cat")
con$drop()
con$insert(
  list(
    name = "fluffy",
    food = data.frame(
      date = "2022-02-12",
      type = "fish"
    )
  )
)
#> List of 6
#>  $ nInserted  : int 1
#>  $ nMatched   : int 0
#>  $ nModified  : int 0
#>  $ nRemoved   : int 0
#>  $ nUpserted  : int 0
#>  $ writeErrors: list()
con$find()
#>     name             food
#> 1 fluffy 2022-02-12, fish

con$insert(
  list(
    name = "minette",
    food = data.frame(
      date = "2022-02-12",
      type = "cake"
    )
  )
)
#> List of 6
#>  $ nInserted  : int 1
#>  $ nMatched   : int 0
#>  $ nModified  : int 0
#>  $ nRemoved   : int 0
#>  $ nUpserted  : int 0
#>  $ writeErrors: list()
con$find()
#>      name             food
#> 1  fluffy 2022-02-12, fish
#> 2 minette 2022-02-12, cake
```

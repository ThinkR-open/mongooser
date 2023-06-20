
<!-- README.md is generated from README.Rmd. Please edit that file -->

# mongooser

<!-- badges: start -->
<!-- badges: end -->

\[WIP / DO NOT USE IN PRODUCTION\]

The goal of mongooser is to port [mongoosejs](https://mongoosejs.com/)
to R, for a more, predictable use of MongoDB in a production context.

## Installation

You can install the development version of mongooser like so:

``` r
pak::pak("thinkr-open/mongooser")
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
they’ll do it, and then some data engineer will cry and scream to scrap
and restructure the data to be usable.

Here is a simple example:

``` r
system("docker run -p 27017:27017 -d mongo")
Sys.sleep(10)
```

``` r
fridge <- mongolite::mongo()
monday_meal <- list(
  day = Sys.Date() + 1,
  ingredient = c("tofu", "brocoli"),
  to_reheat = TRUE,
  box = "blue"
)

fridge$insert(monday_meal)
#> List of 6
#>  $ nInserted  : int 1
#>  $ nMatched   : int 0
#>  $ nModified  : int 0
#>  $ nRemoved   : int 0
#>  $ nUpserted  : int 0
#>  $ writeErrors: list()
```

``` r
class(monday_meal)
#> [1] "list"

fridge_find <- fridge$find()

class(fridge_find)
#> [1] "data.frame"

fridge_iterate <- fridge$iterate()$one()

class(fridge_iterate)
#> [1] "list"
```

It’s even more intersting if you look at the detail structure of each
element:

``` r
dplyr::glimpse(monday_meal)
#> List of 4
#>  $ day       : Date[1:1], format: "2023-06-21"
#>  $ ingredient: chr [1:2] "tofu" "brocoli"
#>  $ to_reheat : logi TRUE
#>  $ box       : chr "blue"
dplyr::glimpse(fridge_find)
#> Rows: 1
#> Columns: 4
#> $ day        <list> "2023-06-21"
#> $ ingredient <list> <"tofu", "brocoli">
#> $ to_reheat  <list> TRUE
#> $ box        <list> "blue"
dplyr::glimpse(fridge_iterate)
#> List of 4
#>  $ day       :List of 1
#>   ..$ : chr "2023-06-21"
#>  $ ingredient:List of 2
#>   ..$ : chr "tofu"
#>   ..$ : chr "brocoli"
#>  $ to_reheat :List of 1
#>   ..$ : logi TRUE
#>  $ box       :List of 1
#>   ..$ : chr "blue"
```

Let’s insert another list:

``` r
tuesday_meal <- list(
  day = Sys.Date() + 2,
  ingredient = "pasta",
  box = "red"
)

fridge$insert(tuesday_meal)
#> List of 6
#>  $ nInserted  : int 1
#>  $ nMatched   : int 0
#>  $ nModified  : int 0
#>  $ nRemoved   : int 0
#>  $ nUpserted  : int 0
#>  $ writeErrors: list()
```

Depending on what you query, you won’t get the same structure:

``` r
dplyr::glimpse(
  fridge$iterate('{"box": "blue"}')$one()
)
#> List of 4
#>  $ day       :List of 1
#>   ..$ : chr "2023-06-21"
#>  $ ingredient:List of 2
#>   ..$ : chr "tofu"
#>   ..$ : chr "brocoli"
#>  $ to_reheat :List of 1
#>   ..$ : logi TRUE
#>  $ box       :List of 1
#>   ..$ : chr "blue"
```

``` r
dplyr::glimpse(
  fridge$iterate('{"box": "red"}')$one()
)
#> List of 3
#>  $ day       :List of 1
#>   ..$ : chr "2023-06-22"
#>  $ ingredient:List of 1
#>   ..$ : chr "pasta"
#>  $ box       :List of 1
#>   ..$ : chr "red"
```

As MongoDB & `{mongolite}` doesn’t inforce any kind of type on
read/write, it can be hard to rely on the output.

`{mongooser}` tries to solve that issue by porting
[mongoosejs](https://mongoosejs.com/), an object modeling tooling for
MongoDB and NodeJS, to R.

## Here is an example

    docker run -d -p 2811:27017 mongo:3.4

The comments are the correponding mongoosejs codes

``` r
# const mongoose = require('mongoose');
library(mongooser)

# mongoose.connect("mongodb://127.0.0.1:27017/test")
mongooser_connect(
  db = "test",
  url = "mongodb://localhost",
  verbose = FALSE,
  options = mongolite::ssl_options()
)
```

We’ll then build a model, which is a schema for our data:

``` r
# const Cat = mongoose.model('Cat', { name: String });
Food <- model(
  "Food",
  properties = list(
    day = \(x) structure(NA_real_, class = "Date"),
    ingredient = character,
    box = character,
    to_reheat = logical
  ),
  validator = list(
    day = lubridate::ymd,
    ingredient = as.character,
    box = as.character,
    to_reheat = as.logical
  )
)
```

Let’s empty our collection first:

``` r
Food$drop()
```

Here, properties is a list of function that returns a data type. It
should be one of base R data type, or a function that returns a
datatype. If you want to build your own properties, it should be a
function that takes one argument (the lenght) and return a repetition of
that data type.

You can then create an instance of that model and save it:

``` r
monday <- Food$new(
  monday_meal
)
monday$save()
#> List of 6
#>  $ nInserted  : int 1
#>  $ nMatched   : int 0
#>  $ nModified  : int 0
#>  $ nRemoved   : int 0
#>  $ nUpserted  : int 0
#>  $ writeErrors: list()

tuesday <- Food$new(
  tuesday_meal
)
tuesday$save()
#> List of 6
#>  $ nInserted  : int 1
#>  $ nMatched   : int 0
#>  $ nModified  : int 0
#>  $ nRemoved   : int 0
#>  $ nUpserted  : int 0
#>  $ writeErrors: list()
```

Then, you can query the model:

``` r
dplyr::glimpse(
  Food$find()
)
#> List of 2
#>  $ :List of 4
#>   ..$ day       : Date[1:1], format: "2023-06-21"
#>   ..$ ingredient: chr [1:2] "tofu" "brocoli"
#>   ..$ box       : chr "blue"
#>   ..$ to_reheat : logi TRUE
#>  $ :List of 4
#>   ..$ day       : Date[1:1], format: "2023-06-22"
#>   ..$ ingredient: chr "pasta"
#>   ..$ box       : chr "red"
#>   ..$ to_reheat : logi FALSE
```

List the number of items :

``` r
Food$count_documents()
#> [1] 2
```

Query one item with `find_one()`. Note that this will return the first
element matching the query, that does not mean that there are no other
records matching this query:

``` r
Food$find_one()
#> $day
#> [1] "2023-06-21"
#> 
#> $ingredient
#> [1] "tofu"    "brocoli"
#> 
#> $box
#> [1] "blue"
#> 
#> $to_reheat
#> [1] TRUE
```

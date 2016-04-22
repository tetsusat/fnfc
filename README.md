# fnfc

`fnfc` is a flexilble netflow collector. `fnfc` understand any data flowset in any form `flexibly` depending on a template flowset.

## Prerequisite

Before installing `fnfc`, you need to install the packages below.

* MongoDB (v3.0.x, v3.2.x)
* Node.js (v0.10.x)
* NPM (v1.3.x)

## Install

To install `fnfc`, `git clone` the source first, then install dependent libraries with `npm install`.

```sh
$ git clone http://gitlab.cisco.com/tetsusat/fnfc.git
$ cd fnfc/
$ npm install
```

## Run 

```sh
$ node lib/fnfc
```

## Configure

To configure `fnfc` parameters, edit `config/fnfc.json`.


```
{
    "fnfc" : {
        "port" : 2055
    },
    "logger" : {
        "level" : "verbose"
    },
    "mongodb" : {
        "ip" : "localhost",
        "port" : 27017,
        "db" : "fnfc",
        "collection" : {
            "records" : "records"
        }
    }
}
```

## License

MIT
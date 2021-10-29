## How to Build

```
$ mvn clean package
```

## How to Run

```
$ mvn gatling:test
```

## Extract data from logs

To extract request body from `gatling.log` file you must make some replacements based on regex:
```
replace "\n          "             with ""
replace "\n        \}\n        \}" with "}"
replace "^(?!        \{).*\n"      with ""
replace "        \{"               with "{"
```

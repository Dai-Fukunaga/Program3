# CS541 Program 3
"Program 2" is an assignment for CS541.

## Description
This program is for Type Checker and Code Checker.

## Author
Dai Fukunaga

## Date
04/07/2023

## Getting Started
### Requires
* Ubuntu 22.04.2 LTS
* bison (GNU Bison) 3.8.2
* flex 2.6.4
* g++ (Ubuntu 11.3.0-1ubuntu1~22.04) 11.3.0
* GNU Make 4.3

### Executing Program
* Compile the codes
```bash
make
```

* Run the program without input files
```bash
./code-gen
```
This program reads standard input forever until `EOF`. Therefore, you have to type `Ctrl+D` at the end of the input.

* Run the program with an input file
```bash
./code-gen < input_file_path
```

* Delete the execute programs
```bash
make clean
```

## Test Cases
There are many test cases in the `tests` directory. <br>
For example, if you want to test a `01_calculate_in.txt` file, run like below.
```bash
./code-gen < ./tests/01_calculate_in.txt
```
You can see the expected result in a `01_calculate_out.txt` file.

## Design
The convert function converts the type so that the types match. <br>
I changed the order of the `enum class Type` in `type.h`. Because I want to make a convert function. DO NOT CHANGE the order of this enum.

## Bugs
No bugs right now.

## References
No references right now.

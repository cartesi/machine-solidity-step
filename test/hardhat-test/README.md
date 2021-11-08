
# Hardhat tests

This tool executes `machine solidity step` tests on hardhat instance.

## Getting Started

Install dependencies and build contracts
> yarn



## Run sequence tests

Start local hardhat node and generate localhost deployment files in `deployments/localhost` directory
> npx hardhat node
 
Unpack files generated from the C++ machine emulator using `brotli` tool to particular directory, e.g.:
```code
brotli -c -d ./rv64mi-p-csr.json.br > rv64mi-p-csr.json
```
Updated `proofs.json` file with the list of the tests that should be executed, e.g.:
```code
{
    "path": "<path_to_folder_with_tests>",
    "proofs": [
        "rv64mi-p-access.json",
        "rv64mi-p-breakpoint.json",
    ]
}
```
Execute sequence on external hardhat node (only one test makes sense):
```code
 cargo run -- --deployments=../../deployments/localhost --mode=sequence --proofs-config=<path_to>/proofs.json --node=http://localhost:8545
```

Execute sequence tests with hardhat node automatic start/finish (local hardhat node should not be running):

```code
 cargo run -- --deployments=../../deployments/localhost --mode=sequence --proofs-config=<path_to>/proofs.json
```

## Execute Run tests

Start local hardhat node and generate ramtest deployment files in `deployments/ramtest` directory
```code
npx hardhat node --as-network ramtest
```

Acquire files from generated from C++ emulator and test .bin files listed in test_list.json:
```
0000000000000000--0000000000001000.bin
0000000000001000--000000000000f000.bin
0000000002000000--00000000000c0000.bin
0000000040008000--0000000000001000.bin
test_list.json
```

`loads.json` file defines how the C++ emulator machine state is loaded:
```
{
    "path": "<path_to_directory>",
    "loads":[
        {
            "file": "0000000000000000--0000000000001000.bin", 
            "position": 0
        },
        {
            "file": "0000000000001000--000000000000f000.bin", 
            "position": 4096
        },
        {
            "file": "0000000002000000--00000000000c0000.bin", 
            "position": 33554432
        },
        {
            "file": "0000000040008000--0000000000001000.bin", 
            "position": 1073774592
        }
    ]
}
```
 
Execute run test on external hardhat node (only one test makes sense):
```code
 cargo run  -- --deployments=../../deployments/ramtest --mode=run --loads-config=<path_to>/loads.json --tests-config=<path_to>/test_list.json --node=http://localhost:8545
```

Execute run tests on internally started hardhat node:
```code
 cargo run  -- --deployments=../../deployments/ramtest --mode=run --loads-config=<path_to>/loads.json --tests-config=<path_to>/test_list.json
```


## Contributing

Thank you for your interest in Cartesi! Head over to our [Contributing Guidelines](CONTRIBUTING.md) for instructions on how to sign our Contributors Agreement and get started with Cartesi!

Please note we have a [Code of Conduct](CODE_OF_CONDUCT.md), please follow it in all your interactions with the project.

## Authors

* *Marko Atanasievski*

## License
The machine-solidity-step repository and all contributions are licensed under
[APACHE 2.0](https://www.apache.org/licenses/LICENSE-2.0). Please review our [LICENSE](LICENSE) file.



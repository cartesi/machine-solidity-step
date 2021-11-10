mod utils;

use getopts::Options;
use serde::{Deserialize, Serialize};
use std::convert::TryFrom;

use std::path::PathBuf;
use std::{thread, time};
use web3::ethabi::ethereum_types::H160;
use web3::ethabi::Address;
use web3::types::{Bytes, CallRequest, TransactionRequest, H256};
use web3::Web3;

const HARDHAT_STARTUP_COUNTER: u64 = 150;

#[derive(Serialize, Deserialize, Debug)]
struct Access {
    r#type: String,
    address: u64,
    read: Option<String>,
    written: Option<String>,
}

#[derive(Serialize, Deserialize, Debug)]
struct Cycles {
    init_cycles: u64,
    final_cycles: u64,
}

#[derive(Serialize, Deserialize, Debug)]
struct Step {
    accesses: Vec<Access>,
    #[serde(flatten)]
    cycles: Cycles,
}

#[derive(Serialize, Deserialize, Debug)]
struct SequenceInfo {
    test: String,
    period: u64,
    start: u64,
}

#[derive(Serialize, Deserialize, Debug)]
struct Sequence {
    steps: Vec<Step>,
    #[serde(flatten)]
    info: SequenceInfo,
}

#[derive(Serialize, Deserialize, Debug)]
struct StateFile {
    file: String,
    position: u64,
}

#[derive(Serialize, Deserialize, Debug)]
struct RunTest {
    file: String,
    mcycle: u64,
}

enum Mode {
    Run,
    Proof,
    Sequence,
}

fn print_usage(program: &str, opts: Options) {
    let brief = format!(
        "Usage: {} [options] --mode=<run|proof|sequence> <test_file>",
        program
    );
    print!("{}", opts.usage(&brief));
}

async fn start_hardhat_local_node(
    ramtest: bool,
    node_address: &String,
) -> Result<u32, Box<dyn std::error::Error>> {
    let output = if ramtest {
        std::process::Command::new("npx")
            .arg("hardhat")
            .arg("node")
            .arg("--as-network")
            .arg("ramtest")
            .spawn()
            .expect("Unable to launch local hardhat node")
    } else {
        std::process::Command::new("npx")
            .arg("hardhat")
            .arg("node")
            .spawn()
            .expect("Unable to launch local hardhat node")
    };
    let mut counter = 0;
    let transport = match web3::transports::Http::new(&node_address) {
        Ok(http) => http,
        Err(_) => {
            panic!("Transport error");
        }
    };
    let w3 = web3::Web3::new(transport);
    while counter < HARDHAT_STARTUP_COUNTER {
        thread::sleep(time::Duration::from_millis(100));
        match w3.net().version().await {
            Ok(_) => {
                println!("Hardhat is alive!");
                break;
            }
            Err(_) => {}
        };
        counter += 1;
    }
    println!("Hardhat node started with pid='{}'", output.id());
    Ok(output.id())
}

/// Kill process with provided pid
fn try_stop_process(pid: u32) -> std::process::ExitStatus {
    println!("Stopping local hardhat node. with pid {}", pid);
    let error_message = format!("Error destroying process with pid {}", pid);
    let mut child = std::process::Command::new("kill")
        .arg(&pid.to_string())
        .spawn()
        .expect(&error_message);
    child.wait().expect(&error_message)
}

async fn send_contract_transaction(
    w3: &Web3<web3::transports::Http>,
    contract_address: &String,
    input_data: Bytes,
) -> Result<H256, Box<dyn std::error::Error>> {
    println!("Sending transaction to contract: {}", contract_address);
    let contract_address_h160: Address =
        H160(<[u8; 20]>::try_from(&(utils::from_hex(contract_address).unwrap()).0[0..20]).unwrap());
    let tx = TransactionRequest {
        from: w3.eth().accounts().await.unwrap()[0],
        to: Some(contract_address_h160),
        gas: None,
        gas_price: None,
        value: None,
        data: Some(input_data),
        nonce: None,
        condition: None,
        transaction_type: None,
        access_list: None,
    };
    let tx_hash = w3.eth().send_transaction(tx).await?;
    println!(
        "Trancation to contract {:?} sent, TX Hash: {:?}",
        contract_address, tx_hash
    );
    Ok(tx_hash)
}

async fn call_contract(
    w3: &Web3<web3::transports::Http>,
    contract_address: &String,
    input_data: Bytes,
) -> Result<Bytes, Box<dyn std::error::Error>> {
    println!(
        "Sending step transaction to step contract: {}",
        contract_address
    );
    let contract_address_h160: Address =
        H160(<[u8; 20]>::try_from(&(utils::from_hex(contract_address).unwrap()).0[0..20]).unwrap());
    let call_request = CallRequest {
        from: Some(w3.eth().accounts().await.unwrap()[0]),
        to: Some(contract_address_h160),
        gas: None,
        gas_price: None,
        value: None,
        data: Some(input_data),
        transaction_type: None,
        access_list: None,
    };
    let result = w3.eth().call(call_request, None).await?;
    println!(
        "Call request to contract {:?} sent, TX Hash: {:?}",
        contract_address, result
    );
    Ok(result)
}

async fn preload_emulator_memory_from_file(
    w3: &Web3<web3::transports::Http>,
    contract_address: &String,
    position: u64,
    file: &String,
) -> Result<(), Box<dyn std::error::Error>> {
    println!(
        "Preloading momery, file {} to position {}",
        &file, &position
    );
    let file_data: Bytes = utils::load_file_as_bytes(file);

    let contract_address_h160: Address =
        H160(<[u8; 20]>::try_from(&(utils::from_hex(contract_address).unwrap()).0[0..20]).unwrap());
    for index in (0..file_data.0.len()).step_by(8) {
        let byte_position = position + index as u64;

        let input = utils::mi_pure_write_encode_input(
            &w3,
            &byte_position,
            8,
            &file_data.0[index..index + 8],
        )
        .await;
        let tx = TransactionRequest {
            from: w3.eth().accounts().await.unwrap()[0],
            to: Some(contract_address_h160),
            gas: None,
            gas_price: None,
            value: None,
            data: Some(input),
            nonce: None,
            condition: None,
            transaction_type: None,
            access_list: None,
        };
        let _tx_hash = w3.eth().send_transaction(tx).await?;
        // println!(
        //     "Memory write byte transation, position {}, u64: {:?} to contract {:?} sent, TX Hash: {:?}", byte_position, &file_data.0[index..index + 8],
        //     contract_address, tx_hash
        // );
    }

    Ok(())
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args: Vec<String> = std::env::args().collect();
    let program = args[0].clone();
    let mut opts = Options::new();
    opts.optopt("", "node", "Address of the Ethereum node to connect to", "");
    opts.optopt(
        "",
        "deployments",
        "<path> Directory with info about contracts deployed on local hardhat network",
        "",
    );
    opts.optopt(
        "",
        "proofs-config",
        "<path> Configuration file containing the proof tests paths",
        "",
    );
    opts.optopt("", "mode", "Mode of test", "MODE_TYPE");
    opts.optopt(
        "",
        "loads-config",
        "<path> Configuration file containing the load paths of emulator machine state",
        "",
    );
    opts.optopt(
        "",
        "tests-config",
        "<path> Configuration of the run tests to execute",
        "",
    );
    opts.optflag("h", "help", "show this help message and exit");
    let matches = opts.parse(&args[1..])?;
    if matches.opt_present("h") {
        print_usage(&program, opts);
        return Ok(());
    }

    // Determine test mode
    let mode_str: String = matches
        .opt_get("mode")?
        .expect("Mode type definition is missing");
    println!("Mode is: {}", mode_str);
    let mode: Mode = match &mode_str[..] {
        "run" => Mode::Run,
        "sequence" => Mode::Sequence,
        "proof" => Mode::Proof,
        _ => panic!("Mode not correctly specified"),
    };

    // Get addresses of contracts
    let mut contract_addresses: std::collections::HashMap<String, String> =
        std::collections::HashMap::new();
    let deployed_contracts_dir: String =
        matches.opt_get_default("deployments", "../../deployments/localhost".to_string())?;
    let contract_config_files = std::fs::read_dir(deployed_contracts_dir)?
        .filter(|val| val.is_ok())
        .map(|res| res.unwrap().path())
        .filter(|val| val.extension().unwrap_or_default() == &std::ffi::OsString::from("json"))
        .collect::<Vec<PathBuf>>();
    for contract_config_file in contract_config_files.iter() {
        if let Some(contract_name) = contract_config_file.file_stem() {
            if let Ok(contract_name) = contract_name.to_os_string().into_string() {
                let file = std::fs::File::open(contract_config_file)
                    .expect("Unable to open contract configuration file");
                let json: serde_json::Value =
                    serde_json::from_reader(file).expect("JSON was not well-formatted");
                if let Some(contract_address) = json.get("address") {
                    println!(
                        "Contract name: {} deployed at {}",
                        contract_name, contract_address
                    );
                    contract_addresses.insert(
                        contract_name,
                        contract_address.to_string().replace(&['\"'][..], ""),
                    );
                }
            }
        }
    }

    // If node address is provided, use external node
    // If it is not provided, start hardhat node
    let mut node_address: String = matches.opt_get_default("node", "".to_string())?;
    let local_hardhat_node: bool = node_address == "".to_string();
    if local_hardhat_node {
        node_address = "http://localhost:8545".to_string();
    }

    match mode {
        Mode::Sequence => {
            // Parse json proofs file, get list of test sequence proof json files
            let proofs_config_file_path: String = matches
                .opt_get("proofs-config")?
                .expect("Missing proofs-config - proof confiuration file path argument");
            let proofs_config_file = std::fs::File::open(proofs_config_file_path)
                .expect("Unable to open proofs configuration file");
            let proofs_config_json: serde_json::Value = serde_json::from_reader(proofs_config_file)
                .expect("Proofs config json file was not well-formatted");
            let proofs: Vec<String> = serde_json::from_str(
                &proofs_config_json
                    .get("proofs")
                    .expect("Unable to get proofs value from json")
                    .to_string(),
            )?;
            let path: String = proofs_config_json
                .get("path")
                .expect("Unable to geth path value from configration file")
                .to_string();

            // Go through list of test sequence files, for every test start new hardhat instance
            // and perform sequence test
            for proof_file_name in proofs {
                let proof_file_path = (path.clone() + &proof_file_name).replace(&['\"'][..], "");
                let proof_file = std::fs::File::open(&proof_file_path).expect(&format!(
                    "Unable to open proof file on path {}",
                    &proof_file_path
                ));
                let sequence_proofs_json: serde_json::Value = serde_json::from_reader(proof_file)
                    .expect(&format!(
                        "Test sequence proofs json file {} was not well-formatted",
                        proof_file_name
                    ));
                let sequences: Vec<Sequence> =
                    serde_json::from_str::<Vec<Sequence>>(&sequence_proofs_json.to_string())?;

                // Go through all sequences (test files)
                for sequence in sequences {
                    let mut hardhat_pid = 0;
                    if local_hardhat_node {
                        println!(
                            "Starting local hardhat node for test {}",
                            sequence.info.test
                        );
                        hardhat_pid = start_hardhat_local_node(false, &node_address).await?;
                    }

                    let transport = match web3::transports::Http::new(&node_address) {
                        Ok(http) => http,
                        Err(err) => {
                            println!("Error connecting to hardhat node {}", err.to_string());
                            if hardhat_pid != 0 {
                                try_stop_process(hardhat_pid);
                            }
                            panic!("Could not create web3 instance, failed to execute tests!");
                        }
                    };
                    let w3 = web3::Web3::new(transport);
                    println!(
                        "Node address is {}, version: {} block number: {}",
                        &node_address,
                        w3.net().version().await?,
                        w3.eth().block_number().await?
                    );
                    println!(
                        "Performing test for file {}, period: {} start {} number of steps {}",
                        &sequence.info.test,
                        sequence.info.period,
                        sequence.info.start,
                        sequence.steps.len()
                    );
                    // Go through steps and execute them
                    for (index, step) in sequence.steps.iter().enumerate() {
                        println!("Step({}/{})", index + 1, sequence.steps.len());
                        let number_of_accesses = step.accesses.len();
                        let mut rw_positions: Vec<u64> = Vec::with_capacity(number_of_accesses);
                        let mut rw_values: Vec<Bytes> = Vec::with_capacity(number_of_accesses);
                        let mut was_read: Vec<bool> = Vec::with_capacity(number_of_accesses);
                        for access in &step.accesses {
                            rw_positions.push(access.address);
                            if access.r#type == "read" {
                                rw_values.push(
                                    utils::from_hex(
                                        access
                                            .read
                                            .as_ref()
                                            .expect("Missing read value in access description"),
                                    )
                                    .unwrap(),
                                );
                                was_read.push(true);
                            } else {
                                rw_values.push(
                                    utils::from_hex(
                                        &access
                                            .written
                                            .as_ref()
                                            .expect("Missing write value in access description"),
                                    )
                                    .unwrap(),
                                );
                                was_read.push(false);
                            }
                        }
                        let input: Bytes =
                            utils::step_encode_input(&w3, &rw_positions, &rw_values, &was_read)
                                .await;
                        // Execute message call to contract on local hardhat node
                        match send_contract_transaction(&w3, &contract_addresses["Step"], input)
                            .await
                        {
                            Ok(_) => {}
                            Err(err) => {
                                println!("Error connecting to hardhat node {}", err.to_string());
                                if hardhat_pid != 0 {
                                    try_stop_process(hardhat_pid);
                                }
                                panic!("Test execution failed");
                            }
                        }
                    }
                    println!("Performing test {} finished", &sequence.info.test);
                    if hardhat_pid != 0 {
                        try_stop_process(hardhat_pid);
                    }
                }
            }
        }
        Mode::Proof => {
            panic!("Proof tests are currently not supported!");
        }
        Mode::Run => {
            // Execute run tests
            // Parse json loads configuration file, get list of state files
            let loads_config_file_path: String = matches
                .opt_get("loads-config")?
                .expect("Missing loads-config - loads configuration file path argument");
            let loads_config_file = std::fs::File::open(&loads_config_file_path)
                .expect("Unable to open loads configuration file");
            let loads_config_json: serde_json::Value = serde_json::from_reader(loads_config_file)
                .expect("Loads config json file was not well-formatted");
            let state_folder_path: String = loads_config_json
                .get("path")
                .expect("Unable to geth path value from loads configuration file")
                .to_string()
                .replace(&['\"'][..], "");
            let loads_json = loads_config_json
                .get("loads")
                .expect("Unable to get list of state files")
                .to_string();
            let state_files: Vec<StateFile> = serde_json::from_str::<Vec<StateFile>>(&loads_json)?
                .into_iter()
                .map(|mut val| {
                    val.file = String::from(&state_folder_path) + &val.file;
                    val
                })
                .collect();
            // Parse json tests configuration file, get list of run tests
            let tests_config_file_path: String = matches
                .opt_get("tests-config")?
                .expect("Missing tests-config - loads configuration file path argument");
            let tests_config_file = std::fs::File::open(tests_config_file_path)
                .expect("Unable to open tests configuration file");
            let tests_config_json: serde_json::Value = serde_json::from_reader(tests_config_file)
                .expect("Tests config json file was not well-formatted");
            let tmp = std::ffi::OsString::from(&loads_config_file_path);
            let test_folder_path = std::path::Path::new(&tmp)
                .parent()
                .expect("Unable to get test folder path")
                .to_str()
                .expect("Unable to get test folder path");
            let tests_json = tests_config_json
                .get("tests")
                .expect("Unable to get list of tests")
                .to_string();
            let run_tests: Vec<RunTest> = serde_json::from_str::<Vec<RunTest>>(&tests_json)?
                .into_iter()
                .map(|mut val| {
                    val.file = String::from(test_folder_path) + "/" + &val.file;
                    val
                })
                .collect();
            println!("Tests:{:#?}", tests_config_json);

            // Execute tests one by one
            for test in run_tests {
                let mut hardhat_pid = 0;
                if local_hardhat_node {
                    println!("Starting local hardhat node for test {}", test.file);
                    hardhat_pid = start_hardhat_local_node(true, &node_address).await?;
                }
                println!("Executing Run test for file {}", test.file);
                let transport = match web3::transports::Http::new(&node_address) {
                    Ok(http) => http,
                    Err(err) => {
                        println!("Error connecting to hardhat node {}", err.to_string());
                        if hardhat_pid != 0 {
                            try_stop_process(hardhat_pid);
                        }
                        panic!("Could not create web3 instance, failed to execute tests!");
                    }
                };
                let w3 = web3::Web3::new(transport);
                println!(
                    "Node address is {}, version: {} block number: {}",
                    &node_address,
                    w3.net().version().await?,
                    w3.eth().block_number().await?
                );

                println!("Loading machine state...");
                // Preload memory with initial machine state
                for state_file in &state_files {
                    println!("Writing state file {} ...", state_file.file);
                    preload_emulator_memory_from_file(
                        &w3,
                        &contract_addresses["TestMemoryInteractor"],
                        state_file.position,
                        &state_file.file,
                    )
                    .await?;
                    println!("Finished writing state file {}", state_file.file);
                }
                println!("Finished loading state files...");

                let reset_yield_data: Bytes =
                    utils::mi_set_ifflags_yield_encode_input(&w3, false).await;

                // Load test program
                preload_emulator_memory_from_file(
                    &w3,
                    &contract_addresses["TestMemoryInteractor"],
                    0x80000000,
                    &test.file,
                )
                .await?;

                let mut halt: bool;
                let dummy_rw_position: Vec<u64> = Vec::new();
                let dummy_rw_valus: Vec<Bytes> = Vec::new();
                let dummy_was_read: Vec<bool> = Vec::new();
                let mut step_counter = 0;
                loop {
                    // Call step
                    let input: Bytes = utils::step_encode_input(
                        &w3,
                        &dummy_rw_position,
                        &dummy_rw_valus,
                        &dummy_was_read,
                    )
                    .await;
                    println!("Performing step number: {}", step_counter);
                    step_counter = step_counter + 1;
                    match send_contract_transaction(&w3, &contract_addresses["Step"], input).await {
                        Ok(_) => {}
                        Err(err) => {
                            println!("Error executing step transaction {}", err.to_string());
                            if hardhat_pid != 0 {
                                try_stop_process(hardhat_pid);
                            }
                            panic!("Test execution failed");
                        }
                    }

                    // Read halt flag
                    let input: Bytes = utils::mi_read_halt_encode_input(&w3).await;
                    halt = match call_contract(
                        &w3,
                        &contract_addresses["TestMemoryInteractor"],
                        input,
                    )
                    .await
                    {
                        Ok(result) => {
                            if result.0[31] == 1 {
                                true
                            } else {
                                false
                            }
                        }
                        Err(err) => {
                            println!("Error reading halt flag {}", err.to_string());
                            if hardhat_pid != 0 {
                                try_stop_process(hardhat_pid);
                            }
                            panic!("Test execution failed");
                        }
                    };

                    if halt == true {
                        //Todo do check here
                        println!("Finished test {}", test.file);
                        break;
                    }

                    match send_contract_transaction(
                        &w3,
                        &contract_addresses["TestMemoryInteractor"],
                        reset_yield_data.clone(),
                    )
                    .await
                    {
                        Ok(_) => {}
                        Err(err) => {
                            println!("Error resetting yield data {}", err.to_string());
                            if hardhat_pid != 0 {
                                try_stop_process(hardhat_pid);
                            }
                            panic!("Test execution failed");
                        }
                    }
                }

                //Check mcycle final value
                let input: Bytes = utils::mi_read_mcycle_encode_input(&w3).await;
                let mcycle_output =
                    match call_contract(&w3, &contract_addresses["TestMemoryInteractor"], input)
                        .await
                    {
                        Ok(result) => result,
                        Err(err) => {
                            println!("Error reading halt flag {}", err.to_string());
                            if hardhat_pid != 0 {
                                try_stop_process(hardhat_pid);
                            }
                            panic!("Test execution failed");
                        }
                    };
                let mut mcycle: u64 = 0;
                for b in mcycle_output.0.iter() {
                    mcycle = mcycle << 8;
                    mcycle = mcycle + *b as u64;
                }

                let input: Bytes = utils::mi_htif_exit_encode_input(&w3).await;
                let exit_output =
                    match call_contract(&w3, &contract_addresses["TestMemoryInteractor"], input)
                        .await
                    {
                        Ok(result) => result,
                        Err(err) => {
                            println!("Error reading halt flag {}", err.to_string());
                            if hardhat_pid != 0 {
                                try_stop_process(hardhat_pid);
                            }
                            panic!("Test execution failed");
                        }
                    };

                let mut exit: u64 = 0;
                for b in exit_output.0.iter() {
                    exit = exit << 8;
                    exit = exit + *b as u64;
                }

                println!(
                    "Test {} expected mcycle: {} executed mcycle {} exit: {}",
                    test.file, test.mcycle, mcycle, exit
                );
                if mcycle == test.mcycle {
                    println!("Finished executing test {} and test is SUCCESS", test.file);
                } else {
                    println!("Finished executing test {} and test has FAILED", test.file);
                }

                if hardhat_pid != 0 {
                    try_stop_process(hardhat_pid);
                }

                std::thread::sleep(std::time::Duration::from_secs(10));
            }
        }
    }

    Ok(())
}

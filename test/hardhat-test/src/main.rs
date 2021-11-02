use getopts::Options;
use std::path::PathBuf;

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

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
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
        "loads-config",
        "<path> Configuration file containing the loads paths",
        "",
    );
    opts.optopt(
        "",
        "proofs-config",
        "<path> Configuration file containing the proof tests paths",
        "",
    );
    opts.optopt(
        "",
        "addresses-config",
        "<path> Configuration file with addresses used on contracts' compilation",
        "",
    );
    opts.reqopt("", "mode", "Mode of test", "MODE_TYPE");
    opts.reqopt("", "test", "Test file", "TEST_FILE");
    opts.optopt(
        "",
        "port-checkin",
        "Port to listen for cartesi server manager checkin (default: 50052)",
        "",
    );
    opts.optflag("h", "help", "show this help message and exit");
    let matches = opts.parse(&args[1..])?;
    if matches.opt_present("h") {
        print_usage(&program, opts);
        return Ok(());
    }

    // Determine test mode
    let mode_str: String = matches.opt_get("mode")?.unwrap();
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
    let contractConfigFiles = std::fs::read_dir(deployed_contracts_dir)?
        .filter(|val| val.is_ok())
        .map(|res| res.unwrap().path())
        .filter(|val| val.extension().unwrap_or_default() == &std::ffi::OsString::from("json"))
        .collect::<Vec<PathBuf>>();
    for contractConfigFile in contractConfigFiles.iter() {
        if let Some(contractName) = contractConfigFile.file_stem() {
            if let Ok(contractName) = contractName.to_os_string().into_string() {
                let mut file = std::fs::File::open(contractConfigFile).unwrap();
                let json: serde_json::Value =
                    serde_json::from_reader(file).expect("JSON was not well-formatted");
                if let Some(contractAddress) = json.get("address") {
                    println!(
                        "Contract name: {} deployed at {}",
                        contractName, contractAddress
                    );
                    contract_addresses.insert(contractName, contractAddress.to_string());
                }
            }
        }
    }

    // Create web3 interface, check if Ethereum node is running
    let node_address: String =
        matches.opt_get_default("node", "http://localhost:8545".to_string())?;
    let transport = web3::transports::Http::new(&node_address)?;
    let web3 = web3::Web3::new(transport);
    println!(
        "Node address is {}, version: {} block number: {}",
        &node_address,
        web3.net().version().await?,
        web3.eth().block_number().await?
    );

    Ok(())
}

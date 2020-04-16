// Copyright 2015-2017 Parity Technologies (UK) Ltd.
// This file is part of Parity.

// Parity is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// Parity is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with Parity.  If not, see <http://www.gnu.org/licenses/>.

extern crate ethabi;
#[macro_use]
extern crate ethabi_contract;
extern crate ethabi_derive;
extern crate ethereum_types;
extern crate rustc_hex;
extern crate solaris;
extern crate solc;

use std::fs;

fn main() {
}

use_contract!(mm, "res/TestRamMMInstantiator.abi");
use_contract!(memory_interactor, "res/MemoryInteractor.abi");
use_contract!(step, "res/Step.abi");

#[cfg(test)]
fn setup_ram_test() -> (solaris::evm::Evm, Address) {
    let owner = Address::from_low_u64_be(3);
    let mut evm = solaris::evm();
    
    // deploy util
    let bits_manipulation_code = include_str!("../res/BitsManipulationLibrary.bin").from_hex().unwrap();
    let bits_manipulation_address = evm.with_sender(owner).deploy(&bits_manipulation_code).unwrap();

    let merkle_code = include_str!("../res/Merkle.bin").from_hex().unwrap();
    let merkle_address = evm.with_sender(owner).deploy(&merkle_code).unwrap();
    
    // deploy arbitration
    solc::link(
        vec![format!("@cartesi/util/contracts/BitsManipulationLibrary.sol:BitsManipulationLibrary:{:x}",
            bits_manipulation_address)],
        "TestRamMMInstantiator.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));

    let mm_code = fs::read_to_string(concat!(env!("CARGO_MANIFEST_DIR"), "/res/TestRamMMInstantiator.bin"))
        .unwrap()
        .from_hex()
        .unwrap();
    //let mm_code = include_str!("../res/TestRamMMInstantiator.bin").from_hex().unwrap();
    let mm_address = evm.with_sender(owner).deploy(&mm_code).unwrap();
    
    // deploy machine-solidity
    let shadow_code = include_str!("../res/ShadowAddresses.bin").from_hex().unwrap();
    let shadow_address = evm.with_sender(owner).deploy(&shadow_code).unwrap();

    let riscv_constants_code = include_str!("../res/RiscVConstants.bin").from_hex().unwrap();
    let riscv_constants_address = evm.with_sender(owner).deploy(&riscv_constants_code).unwrap();
    
    solc::link(
        vec![format!("@cartesi/util/contracts/BitsManipulationLibrary.sol:BitsManipulationLibrary:{:x}",
            bits_manipulation_address)],
        "RiscVDecoder.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));

    let riscv_decoder_code = fs::read_to_string(concat!(env!("CARGO_MANIFEST_DIR"), "/res/RiscVDecoder.bin"))
        .unwrap()
        .from_hex()
        .unwrap();
    let riscv_decoder_address = evm.with_sender(owner).deploy(&riscv_decoder_code).unwrap();

    let realtime_clock_code = include_str!("../res/RealTimeClock.bin").from_hex().unwrap();
    let realtime_clock_address = evm.with_sender(owner).deploy(&realtime_clock_code).unwrap();
    
    solc::link(
        vec![format!("RiscVDecoder.sol:RiscVDecoder:{:x}",
            riscv_decoder_address)],
        "BranchInstructions.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("RiscVDecoder.sol:RiscVDecoder:{:x}",
            riscv_decoder_address)],
        "ArithmeticInstructions.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("RiscVDecoder.sol:RiscVDecoder:{:x}",
            riscv_decoder_address)],
        "ArithmeticImmediateInstructions.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("RiscVDecoder.sol:RiscVDecoder:{:x}",
            riscv_decoder_address)],
        "CSRReads.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("RiscVDecoder.sol:RiscVDecoder:{:x}",
            riscv_decoder_address)],
        "StandAloneInstructions.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("RiscVConstants.sol:RiscVConstants:{:x}",
            riscv_constants_address)],
        "BranchInstructions.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("RiscVConstants.sol:RiscVConstants:{:x}",
            riscv_constants_address)],
        "ArithmeticInstructions.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("RiscVConstants.sol:RiscVConstants:{:x}",
            riscv_constants_address)],
        "ArithmeticImmediateInstructions.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("RiscVConstants.sol:RiscVConstants:{:x}",
            riscv_constants_address)],
        "CSRReads.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("RiscVConstants.sol:RiscVConstants:{:x}",
            riscv_constants_address)],
        "StandAloneInstructions.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("RiscVConstants.sol:RiscVConstants:{:x}",
            riscv_constants_address)],
        "EnvTrapIntInstructions.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    
    let branch_code = fs::read_to_string(concat!(env!("CARGO_MANIFEST_DIR"), "/res/BranchInstructions.bin"))
        .unwrap()
        .from_hex()
        .unwrap();
    let branch_address = evm.with_sender(owner).deploy(&branch_code).unwrap();
    
    let arithmetic_code = fs::read_to_string(concat!(env!("CARGO_MANIFEST_DIR"), "/res/ArithmeticInstructions.bin"))
        .unwrap()
        .from_hex()
        .unwrap();
    let arithmetic_address = evm.with_sender(owner).deploy(&arithmetic_code).unwrap();
    
    let arithmetic_immediate_code = fs::read_to_string(concat!(env!("CARGO_MANIFEST_DIR"), "/res/ArithmeticImmediateInstructions.bin"))
        .unwrap()
        .from_hex()
        .unwrap();
    let arithmetic_immediate_address = evm.with_sender(owner).deploy(&arithmetic_immediate_code).unwrap();
    
    let standalone_code = fs::read_to_string(concat!(env!("CARGO_MANIFEST_DIR"), "/res/StandAloneInstructions.bin"))
        .unwrap()
        .from_hex()
        .unwrap();
    let standalone_address = evm.with_sender(owner).deploy(&standalone_code).unwrap();

    let pma_code = include_str!("../res/PMA.bin").from_hex().unwrap();
    let pma_address = evm.with_sender(owner).deploy(&pma_code).unwrap();

    solc::link(
        vec![format!("RealTimeClock.sol:RealTimeClock:{:x}",
            realtime_clock_address)],
        "CSRReads.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    
    let csr_reads_code = fs::read_to_string(concat!(env!("CARGO_MANIFEST_DIR"), "/res/CSRReads.bin"))
        .unwrap()
        .from_hex()
        .unwrap();
    let csr_reads_address = evm.with_sender(owner).deploy(&csr_reads_code).unwrap();
    
    solc::link(
        vec![format!("RealTimeClock.sol:RealTimeClock:{:x}",
            realtime_clock_address)],
        "CLINT.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("RiscVConstants.sol:RiscVConstants:{:x}",
            riscv_constants_address)],
        "CLINT.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    
    let clint_code = fs::read_to_string(concat!(env!("CARGO_MANIFEST_DIR"), "/res/CLINT.bin"))
        .unwrap()
        .from_hex()
        .unwrap();
    let clint_address = evm.with_sender(owner).deploy(&clint_code).unwrap();
    
    solc::link(
        vec![format!("RealTimeClock.sol:RealTimeClock:{:x}",
            realtime_clock_address)],
        "HTIF.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("RiscVConstants.sol:RiscVConstants:{:x}",
            riscv_constants_address)],
        "HTIF.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    
    let htif_code = fs::read_to_string(concat!(env!("CARGO_MANIFEST_DIR"), "/res/CLINT.bin"))
        .unwrap()
        .from_hex()
        .unwrap();
    let htif_address = evm.with_sender(owner).deploy(&htif_code).unwrap();
    
    solc::link(
        vec![format!("RealTimeClock.sol:RealTimeClock:{:x}",
            realtime_clock_address)],
        "CSR.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("RiscVConstants.sol:RiscVConstants:{:x}",
            riscv_constants_address)],
        "CSR.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("RiscVDecoder.sol:RiscVDecoder:{:x}",
            riscv_decoder_address)],
        "CSR.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("CSRReads.sol:CSRReads:{:x}",
            csr_reads_address)],
        "CSR.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    
    let csr_code = fs::read_to_string(concat!(env!("CARGO_MANIFEST_DIR"), "/res/CSR.bin"))
        .unwrap()
        .from_hex()
        .unwrap();
    let csr_address = evm.with_sender(owner).deploy(&csr_code).unwrap();
    
    solc::link(
        vec![format!("RealTimeClock.sol:RealTimeClock:{:x}",
            realtime_clock_address)],
        "CSRExecute.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("RiscVConstants.sol:RiscVConstants:{:x}",
            riscv_constants_address)],
        "CSRExecute.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("RiscVDecoder.sol:RiscVDecoder:{:x}",
            riscv_decoder_address)],
        "CSRExecute.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("CSRReads.sol:CSRReads:{:x}",
            csr_reads_address)],
        "CSRExecute.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("CSR.sol:CSR:{:x}",
            csr_reads_address)],
        "CSRExecute.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    
    let csr_execute_code = fs::read_to_string(concat!(env!("CARGO_MANIFEST_DIR"), "/res/CSRExecute.bin"))
        .unwrap()
        .from_hex()
        .unwrap();
    let csr_execute_address = evm.with_sender(owner).deploy(&csr_execute_code).unwrap();
    
    solc::link(
        vec![format!("RiscVConstants.sol:RiscVConstants:{:x}",
            riscv_constants_address)],
        "Exceptions.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    
    let exceptions_code = fs::read_to_string(concat!(env!("CARGO_MANIFEST_DIR"), "/res/Exceptions.bin"))
        .unwrap()
        .from_hex()
        .unwrap();
    let exceptions_address = evm.with_sender(owner).deploy(&exceptions_code).unwrap();
    
    solc::link(
        vec![format!("Exceptions.sol:Exceptions:{:x}",
            exceptions_address)],
        "EnvTrapIntInstructions.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    
    let env_trap_code = fs::read_to_string(concat!(env!("CARGO_MANIFEST_DIR"), "/res/EnvTrapIntInstructions.bin"))
        .unwrap()
        .from_hex()
        .unwrap();
    let env_trap_address = evm.with_sender(owner).deploy(&env_trap_code).unwrap();

    solc::link(
        vec![format!("RiscVDecoder.sol:RiscVDecoder:{:x}",
            riscv_decoder_address)],
        "VirtualMemory.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("ShadowAddresses.sol:ShadowAddresses:{:x}",
            shadow_address)],
        "VirtualMemory.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("RiscVConstants.sol:RiscVConstants:{:x}",
            riscv_constants_address)],
        "VirtualMemory.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("PMA.sol:PMA:{:x}",
            pma_address)],
        "VirtualMemory.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("CLINT.sol:CLINT:{:x}",
            clint_address)],
        "VirtualMemory.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("HTIF.sol:HTIF:{:x}",
            htif_address)],
        "VirtualMemory.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("Exceptions.sol:Exceptions:{:x}",
            exceptions_address)],
        "VirtualMemory.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    
    let virtual_code = fs::read_to_string(concat!(env!("CARGO_MANIFEST_DIR"), "/res/VirtualMemory.bin"))
        .unwrap()
        .from_hex()
        .unwrap();
    let virtual_address = evm.with_sender(owner).deploy(&virtual_code).unwrap();
    
    solc::link(
        vec![format!("RiscVDecoder.sol:RiscVDecoder:{:x}",
            riscv_decoder_address)],
        "S_Instructions.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("VirtualMemory.sol:VirtualMemory:{:x}",
            shadow_address)],
        "S_Instructions.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    
    let s_code = fs::read_to_string(concat!(env!("CARGO_MANIFEST_DIR"), "/res/S_Instructions.bin"))
        .unwrap()
        .from_hex()
        .unwrap();
    let s_address = evm.with_sender(owner).deploy(&s_code).unwrap();

    solc::link(
        vec![format!("RiscVDecoder.sol:RiscVDecoder:{:x}",
            riscv_decoder_address)],
        "AtomicInstructions.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("VirtualMemory.sol:VirtualMemory:{:x}",
            shadow_address)],
        "AtomicInstructions.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    
    let atomic_code = fs::read_to_string(concat!(env!("CARGO_MANIFEST_DIR"), "/res/AtomicInstructions.bin"))
        .unwrap()
        .from_hex()
        .unwrap();
    let atomic_address = evm.with_sender(owner).deploy(&atomic_code).unwrap();

    solc::link(
        vec![format!("RiscVDecoder.sol:RiscVDecoder:{:x}",
            riscv_decoder_address)],
        "Fetch.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("ShadowAddresses.sol:ShadowAddresses:{:x}",
            shadow_address)],
        "Fetch.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("RiscVConstants.sol:RiscVConstants:{:x}",
            riscv_constants_address)],
        "Fetch.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("PMA.sol:PMA:{:x}",
            pma_address)],
        "Fetch.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("VirtualMemory.sol:VirtualMemory:{:x}",
            virtual_address)],
        "Fetch.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("Exceptions.sol:Exceptions:{:x}",
            exceptions_address)],
        "Fetch.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));

    let fetch_code = fs::read_to_string(concat!(env!("CARGO_MANIFEST_DIR"), "/res/Fetch.bin"))
        .unwrap()
        .from_hex()
        .unwrap();
    let fetch_address = evm.with_sender(owner).deploy(&fetch_code).unwrap();

    solc::link(
        vec![format!("ShadowAddresses.sol:ShadowAddresses:{:x}",
            shadow_address)],
        "Interrupts.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("RiscVConstants.sol:RiscVConstants:{:x}",
            riscv_constants_address)],
        "Interrupts.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("Exceptions.sol:Exceptions:{:x}",
            exceptions_address)],
        "Interrupts.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));

    let interrupts_code = fs::read_to_string(concat!(env!("CARGO_MANIFEST_DIR"), "/res/Interrupts.bin"))
        .unwrap()
        .from_hex()
        .unwrap();
    let interrupts_address = evm.with_sender(owner).deploy(&interrupts_code).unwrap();

    solc::link(
        vec![format!("RiscVInstructions/S_Instructions.sol:S_Instructions:{:x}",
            s_address)],
        "Execute.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("@cartesi/util/contracts/BitsManipulationLibrary.sol:BitsManipulationLibrary:{:x}",
            bits_manipulation_address)],
        "Execute.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("RiscVInstructions/ArithmeticInstructions.sol:ArithmeticInstructions:{:x}",
            arithmetic_address)],
        "Execute.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("RiscVInstructions/ArithmeticImmediateInstructions.sol:ArithmeticImmediateInstructions:{:x}",
            arithmetic_immediate_address)],
        "Execute.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("RiscVDecoder.sol:RiscVDecoder:{:x}",
            riscv_decoder_address)],
        "Execute.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("ShadowAddresses.sol:ShadowAddresses:{:x}",
            shadow_address)],
        "Execute.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("RiscVConstants.sol:RiscVConstants:{:x}",
            riscv_constants_address)],
        "Execute.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("RiscVInstructions/BranchInstructions.sol:BranchInstructions:{:x}",
            branch_address)],
        "Execute.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("RiscVInstructions/AtomicInstructions.sol:AtomicInstructions:{:x}",
            atomic_address)],
        "Execute.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("RiscVInstructions/EnvTrapIntInstructions.sol:EnvTrapIntInstructions:{:x}",
            env_trap_address)],
        "Execute.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("RiscVInstructions/StandAloneInstructions.sol:StandAloneInstructions:{:x}",
            standalone_address)],
        "Execute.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("CSRExecute.sol:CSRExecute:{:x}",
            csr_execute_address)],
        "Execute.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("CSR.sol:CSR:{:x}",
            csr_address)],
        "Execute.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("Exceptions.sol:Exceptions:{:x}",
            exceptions_address)],
        "Execute.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("VirtualMemory.sol:VirtualMemory:{:x}",
            virtual_address)],
        "Execute.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));

    let execute_code = fs::read_to_string(concat!(env!("CARGO_MANIFEST_DIR"), "/res/Execute.bin"))
        .unwrap()
        .from_hex()
        .unwrap();
    let execute_address = evm.with_sender(owner).deploy(&execute_code).unwrap();
    
    solc::link(
        vec![format!("@cartesi/util/contracts/BitsManipulationLibrary.sol:BitsManipulationLibrary:{:x}",
            bits_manipulation_address)],
        "MemoryInteractor.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("HTIF.sol:HTIF:{:x}",
            htif_address)],
        "MemoryInteractor.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("CLINT.sol:CLINT:{:x}",
            clint_address)],
        "MemoryInteractor.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("RiscVConstants.sol:RiscVConstants:{:x}",
            riscv_constants_address)],
        "MemoryInteractor.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("ShadowAddresses.sol:ShadowAddresses:{:x}",
            shadow_address)],
        "MemoryInteractor.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));

    let memory_interactor_code = fs::read_to_string(concat!(env!("CARGO_MANIFEST_DIR"), "/res/MemoryInteractor.bin"))
        .unwrap()
        .from_hex()
        .unwrap();
    let memory_interactor_constructor_code = memory_interactor::constructor(
        memory_interactor_code,
        mm_address
    );
    let memory_interactor_address = evm.with_sender(owner).deploy(&memory_interactor_constructor_code).unwrap();

    solc::link(
        vec![format!("Fetch.sol:Fetch:{:x}",
            fetch_address)],
        "Step.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("Interrupts.sol:Interrupts:{:x}",
            interrupts_address)],
        "Step.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("RiscVDecoder.sol:RiscVDecoder:{:x}",
            riscv_decoder_address)],
        "Step.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("RiscVConstants.sol:RiscVConstants:{:x}",
            riscv_constants_address)],
        "Step.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("ShadowAddresses.sol:ShadowAddresses:{:x}",
            shadow_address)],
        "Step.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));
    solc::link(
        vec![format!("Execute.sol:Execute:{:x}",
            execute_address)],
        "Step.bin".into(),
        concat!(env!("CARGO_MANIFEST_DIR"), "/res/"));

    let step_code = fs::read_to_string(concat!(env!("CARGO_MANIFEST_DIR"), "/res/Step.bin"))
        .unwrap()
        .from_hex()
        .unwrap();
    let step_constructor_code = step::constructor(
        step_code,
        memory_interactor_address
    );
    let step_address = evm.with_sender(owner).deploy(&step_constructor_code).unwrap();
    (evm, mm_address)
}

#[cfg(test)]
use rustc_hex::FromHex;
#[cfg(test)]
use solaris::convert;
#[cfg(test)]
use solaris::wei;

#[cfg(test)]
use ethereum_types::{Address, U256};

#[test]
fn ram_test() {
    let (mut evm, mm_address) = setup_ram_test();
}

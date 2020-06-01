#!/bin/sh

# This script compiles all contracts in the current dir, links libraries 
# using pre-calculated contract addresses. Also filled in the constructor
# arguments for Step and MemoryInteractor contracts


mkdir -p ./build/@cartesi/util/contracts/
mkdir -p ./build/@cartesi/arbitration/contracts/
cd build

# copy dependent contracts from node_modules
cp ../node_modules/@cartesi/util/contracts/* -r @cartesi/util/contracts/
cp ../node_modules/@cartesi/arbitration/contracts/* -r @cartesi/arbitration/contracts/
cp ../contracts/* ./ -r

solc --bin --optimize --overwrite -o $(pwd) *.sol

# These addresses are generated with sender = 69, nounce starting from 0,
# incrememt by 1 in the following order
bits_address="8fa079a96ce08f6e8a53c1c00566c434b248bfc4"
mm_address="5e9ff79d5002ab94bafddb12b00b6f2a8de4aebc"
shadow_address="e03a25a43cf789df184f50668e6d87078fa61023"
riscv_constants_address="e971bd4ab7d083946f6d4f4111a6c45b802d229a"
riscv_decoder_address="98f2f055133307dc2f4549ee6ac7175a7be17935"
real_time_address="549e1e77d76e161b7412f25ff69098f494c86eea"
branch_address="f95c1bed8b1f53d9659a5522b75f49b2f479bd88"
arithmetic_address="637a8954a92ac1a928bdcacc0720ab1757027a26"
arithmetic_immediate_address="0f8dd8c751d5c523ea5dc87a2fc7e8366304c544"
standalone_address="d09bd99fb0c88734454e675f68c52eede81ccfd1"
pma_address="bfc90cb6082fadfbede53a7deff4eb65fe4c0568"
csr_reads_address="ed3fd91073ca88b01c6780bf09a32f6029ecabb2"
clint_address="6d48ba86564714529158c6f38f3d287a1a5d40de"
htif_address="b381758cd1e1bbcfc52fe3237dc9c9d3c43a76a7"
csr_address="25af8d3292961c82ac506ce69dc227bae15443cf"
csr_execute_address="ed58142ec95a845c9e0ee916cf964a666520dce5"
env_trap_address="dc729832fdd1d6f0c7801549888ab116667f260f"
exceptions_address="e91e3ef07a1f64cdab496a456154352c8466d5b9"
virtual_address="f1cc131112de843363ba5db5b2d8b3b7aed9b418"
s_address="40f560a009734df5fe2403e476f71c5b0741a01f"
atomic_address="fe6a661eafd55109d796171c4f0d9b228f2b59b7"
fetch_address="1ecfb9b88eb1076297aa1b601c4207e1c746e5fd"
interrupts_address="1a57ad4fe582cf034c0ad7710762ab9b37121007"
execute_address="fbac75958518c3be70bc335b428ecf071cbbb21c"
memory_interactor_address="053679655a96792b75b218a376e0dd170be8b4f9"
step_address="c52b3d0598675df528b3dfd3336e04298b109447"

# link contracts binary file with libraries
solc --link \
	--libraries @cartesi/util/contracts/BitsManipulationLibrary.sol:BitsManipulationLibrary:$bits_address \
	TestRamMMInstantiator.bin
solc --link \
	--libraries @cartesi/util/contracts/BitsManipulationLibrary.sol:BitsManipulationLibrary:$bits_address \
	RiscVDecoder.bin
solc --link \
	--libraries RiscVDecoder.sol:RiscVDecoder:$riscv_decoder_address \
	--libraries RiscVConstants.sol:RiscVConstants:$riscv_constants_address \
	ArithmeticInstructions.bin
solc --link \
	--libraries RiscVDecoder.sol:RiscVDecoder:$riscv_decoder_address \
	--libraries RiscVConstants.sol:RiscVConstants:$riscv_constants_address \
	ArithmeticImmediateInstructions.bin
solc --link \
	--libraries RiscVDecoder.sol:RiscVDecoder:$riscv_decoder_address \
	--libraries RiscVConstants.sol:RiscVConstants:$riscv_constants_address \
	StandAloneInstructions.bin
solc --link \
	--libraries RiscVDecoder.sol:RiscVDecoder:$riscv_decoder_address \
	--libraries RiscVConstants.sol:RiscVConstants:$riscv_constants_address \
	BranchInstructions.bin
solc --link \
	--libraries RiscVDecoder.sol:RiscVDecoder:$riscv_decoder_address \
	--libraries RiscVConstants.sol:RiscVConstants:$riscv_constants_address \
	--libraries RealTimeClock.sol:RealTimeClock:$real_time_address \
	CSRReads.bin
solc --link \
	--libraries RiscVConstants.sol:RiscVConstants:$riscv_constants_address \
	--libraries RealTimeClock.sol:RealTimeClock:$real_time_address \
	CLINT.bin
solc --link \
	--libraries RiscVConstants.sol:RiscVConstants:$riscv_constants_address \
	--libraries RealTimeClock.sol:RealTimeClock:$real_time_address \
	HTIF.bin
solc --link \
	--libraries RiscVDecoder.sol:RiscVDecoder:$riscv_decoder_address \
	--libraries RiscVConstants.sol:RiscVConstants:$riscv_constants_address \
	--libraries RealTimeClock.sol:RealTimeClock:$real_time_address \
	--libraries CSRReads.sol:CSRReads:$csr_reads_address \
	CSR.bin
solc --link \
	--libraries RiscVDecoder.sol:RiscVDecoder:$riscv_decoder_address \
	--libraries RiscVConstants.sol:RiscVConstants:$riscv_constants_address \
	--libraries RealTimeClock.sol:RealTimeClock:$real_time_address \
	--libraries CSRReads.sol:CSRReads:$csr_reads_address \
	--libraries CSR.sol:CSR:$csr_address \
	CSRExecute.bin
solc --link \
	--libraries RiscVConstants.sol:RiscVConstants:$riscv_constants_address \
	Exceptions.bin
solc --link \
	--libraries RiscVConstants.sol:RiscVConstants:$riscv_constants_address \
	--libraries Exceptions.sol:Exceptions:$exceptions_address \
	EnvTrapIntInstructions.bin
solc --link \
	--libraries RiscVDecoder.sol:RiscVDecoder:$riscv_decoder_address \
	--libraries RiscVConstants.sol:RiscVConstants:$riscv_constants_address \
	--libraries ShadowAddresses.sol:ShadowAddresses:$shadow_address \
	--libraries PMA.sol:PMA:$pma_address \
	--libraries CLINT.sol:CLINT:$clint_address \
	--libraries HTIF.sol:HTIF:$htif_address \
	--libraries Exceptions.sol:Exceptions:$exceptions_address \
	VirtualMemory.bin
solc --link \
	--libraries RiscVDecoder.sol:RiscVDecoder:$riscv_decoder_address \
	--libraries VirtualMemory.sol:VirtualMemory:$virtual_address \
	S_Instructions.bin
solc --link \
	--libraries RiscVDecoder.sol:RiscVDecoder:$riscv_decoder_address \
	--libraries VirtualMemory.sol:VirtualMemory:$virtual_address \
	AtomicInstructions.bin
solc --link \
	--libraries RiscVDecoder.sol:RiscVDecoder:$riscv_decoder_address \
	--libraries RiscVConstants.sol:RiscVConstants:$riscv_constants_address \
	--libraries ShadowAddresses.sol:ShadowAddresses:$shadow_address \
	--libraries PMA.sol:PMA:$pma_address \
	--libraries VirtualMemory.sol:VirtualMemory:$virtual_address \
	--libraries Exceptions.sol:Exceptions:$exceptions_address \
	Fetch.bin
solc --link \
	--libraries RiscVConstants.sol:RiscVConstants:$riscv_constants_address \
	--libraries ShadowAddresses.sol:ShadowAddresses:$shadow_address \
	--libraries Exceptions.sol:Exceptions:$exceptions_address \
	Interrupts.bin
solc --link \
	--libraries @cartesi/util/contracts/BitsManipulationLibrary.sol:BitsManipulationLibrary:$bits_address \
	--libraries RiscVDecoder.sol:RiscVDecoder:$riscv_decoder_address \
	--libraries RiscVConstants.sol:RiscVConstants:$riscv_constants_address \
	--libraries ShadowAddresses.sol:ShadowAddresses:$shadow_address \
	--libraries RiscVInstructions/BranchInstructions.sol:BranchInstructions:$branch_address \
	--libraries RiscVInstructions/AtomicInstructions.sol:AtomicInstructions:$atomic_address \
	--libraries RiscVInstructions/ArithmeticInstructions.sol:ArithmeticInstructions:$arithmetic_address \
	--libraries \
	RiscVInstructions/ArithmeticImmediateInstructions.sol:ArithmeticImmediateInstructions:$arithmetic_immediate_address \
	--libraries RiscVInstructions/StandAloneInstructions.sol:StandAloneInstructions:$standalone_address \
	--libraries RiscVInstructions/EnvTrapIntInstructions.sol:EnvTrapIntInstructions:$env_trap_address \
	--libraries RiscVInstructions/S_Instructions.sol:S_Instructions:$s_address \
	--libraries CSR.sol:CSR:$csr_address \
	--libraries CSRExecute.sol:CSRExecute:$csr_execute_address \
	--libraries Exceptions.sol:Exceptions:$exceptions_address \
	--libraries VirtualMemory.sol:VirtualMemory:$virtual_address \
	Execute.bin
solc --link \
	--libraries @cartesi/util/contracts/BitsManipulationLibrary.sol:BitsManipulationLibrary:$bits_address \
	--libraries RiscVConstants.sol:RiscVConstants:$riscv_constants_address \
	--libraries ShadowAddresses.sol:ShadowAddresses:$shadow_address \
	--libraries CLINT.sol:CLINT:$clint_address \
	--libraries HTIF.sol:HTIF:$htif_address \
	MemoryInteractor.bin
solc --link \
	--libraries RiscVDecoder.sol:RiscVDecoder:$riscv_decoder_address \
	--libraries RiscVConstants.sol:RiscVConstants:$riscv_constants_address \
	--libraries ShadowAddresses.sol:ShadowAddresses:$shadow_address \
	--libraries Fetch.sol:Fetch:$fetch_address \
	--libraries Interrupts.sol:Interrupts:$interrupts_address \
	--libraries Execute.sol:Execute:$execute_address \
	Step.bin
solc --link \
	--libraries RiscVDecoder.sol:RiscVDecoder:$riscv_decoder_address \
	--libraries RiscVConstants.sol:RiscVConstants:$riscv_constants_address \
	--libraries ShadowAddresses.sol:ShadowAddresses:$shadow_address \
	--libraries Fetch.sol:Fetch:$fetch_address \
	--libraries Interrupts.sol:Interrupts:$interrupts_address \
	--libraries Execute.sol:Execute:$execute_address \
	TestRamStep.bin

# append mm_address to mi_code to mimic constructor code
echo -n "000000000000000000000000${mm_address}" >> MemoryInteractor.bin
# append mi_address to step_code to mimic constructor code
echo -n "000000000000000000000000${memory_interactor_address}" >> Step.bin
# append mi_address to test_ram_step_code to mimic constructor code
echo -n "000000000000000000000000${memory_interactor_address}" >> TestRamStep.bin

cd ../

/// @title TestRamStep
pragma solidity ^0.5.0;

//Libraries
import "../contracts/Step.sol";
import "../contracts/TestRamMMInstantiator.sol";


//TO-DO: use instantiator pattern so we can always use same instance of mm/pc etc
contract TestRamStep {
    // event Print(string message, uint value);
    Step step;
    TestRamMMInstantiator mm;

    event HTIFExit(uint256 _index, uint64 _exitCode, bool _halt);

    constructor(address stepAddress, address testRamMMAddress) public {
        step = Step(stepAddress);
        mm = TestRamMMInstantiator(testRamMMAddress);
    }

    function loop(uint mmIndex) public {
        bool halt = false;
        uint64 exitCode = 0;

        while (!halt) {
            step.step(mmIndex);
            (exitCode, halt) = mm.htifExit(mmIndex);
        }

        emit HTIFExit(mmIndex, exitCode, halt);
    }

}

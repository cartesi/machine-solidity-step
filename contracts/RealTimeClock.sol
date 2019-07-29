/// @title RealTimeClock
pragma solidity ^ 0.5.0;


library RealTimeClock {
    uint64 constant RTC_FREQ_DIV = 100;
    /// \brief Converts from cycle count to time count
    /// \param cycle Cycle count
    /// \returns Time count
    function rtcCycleToTime(uint64 cycle) public pure returns (uint64) {
        return cycle / RTC_FREQ_DIV;
    }

    /// \brief Converts from time count to cycle count
    /// \param time Time count
    /// \returns Cycle count
    function rtcTimeToCycle(uint64 time) public pure returns (uint64) {
        return time * RTC_FREQ_DIV;
    }
}

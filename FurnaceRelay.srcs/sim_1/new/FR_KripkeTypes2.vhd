----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04.05.2023 01:03:13
-- Design Name: 
-- Module Name: FR_KripkeTypes2 - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package FR_KripkeTypes2 is

    type ReadSnapshot_t is record
        demand: std_logic_vector(1 downto 0);
        heat: std_logic;
        state: std_logic_vector(1 downto 0);
        executeOnEntry: boolean;
    end record ReadSnapshot_t;
        
    type WriteSnapshot_t is record
        demand: std_logic_vector(1 downto 0);
        heat: std_logic;
        relayOn: std_logic;
        state: std_logic_vector(1 downto 0);
        nextState: std_logic_vector(1 downto 0);
        executeOnEntry: boolean;
    end record WriteSnapshot_t;

    type TotalSnapshot_t is record
        demand: std_logic_vector(1 downto 0);
        heat: std_logic;
        relayOn: std_logic;
        fr_demand: std_logic_vector(1 downto 0);
        fr_heat: std_logic;
        currentStateIn: std_logic_vector(1 downto 0);
        currentStateOut: std_logic_vector(1 downto 0);
        previousRingletIn: std_logic_vector(1 downto 0);
        previousRingletOut: std_logic_vector(1 downto 0);
        internalStateIn: std_logic_vector(2 downto 0);
        internalStateOut: std_logic_vector(2 downto 0);
        targetStateIn: std_logic_vector(1 downto 0);
        targetStateOut: std_logic_vector(1 downto 0);
        reset: std_logic;
        goalInternalState: std_logic_vector(2 downto 0);
        finished: boolean;
        executeOnEntry: boolean;
        observed: boolean;
    end record TotalSnapshot_t;
    
    type Initial_ReadSnapshot_t is record
        executeOnEntry: boolean;
        observed: boolean;
    end record Initial_ReadSnapshot_t;
    
    type Initial_ReadSnapshots_t is array(0 to 1) of Initial_ReadSnapshot_t;
    
    type Initial_WriteSnapshot_t is record
        nextState: std_logic_vector(1 downto 0);
        executeOnEntry: boolean;
        observed: boolean;
    end record Initial_WriteSnapshot_t;
    
    type Initial_WriteSnapshots_t is array(0 to 5) of Initial_WriteSnapshot_t;
    
    type FROff_ReadSnapshot_t is record
        demand: std_logic_vector(1 downto 0);
        heat: std_logic;
        executeOnEntry: boolean;
        observed: boolean;
    end record FROff_ReadSnapshot_t;
    
    type FROff_ReadSnapshots_t is array(0 to 1457) of FROff_ReadSnapshot_t;
    
    type FROff_WriteSnapshot_t is record
        relayOn: std_logic;
        nextState: std_logic_vector(1 downto 0);
        executeOnEntry: boolean;
        observed: boolean;
    end record FROff_WriteSnapshot_t;
    
    type FROff_WriteSnapshots_t is array(0 to 53) of FROff_WriteSnapshot_t;
    
    type RunnerParameters_t is record
        readSnapshotState: ReadSnapshot_t;
        writeSnapshotState: WriteSnapshot_t;
        nextState: std_logic_vector(1 downto 0);
        finished: boolean;
    end record RunnerParameters_t;
    
    type Runners_t is array(0 to 1611) of RunnerParameters_t;
    
    type CurrentJobs_t is array(0 to 1611) of boolean;
    
    type ObservedState_t is record
        state: std_logic_vector(1 downto 0);
        executeOnEntry: boolean;
        observed: boolean;
    end record ObservedState_t;
    
    type AllStates_t is array(0 to 5) of ObservedState_t;
    type States_t is array(0 to 1611) of std_logic_vector(1 downto 0);
    type Demands_t is array(0 to 1611) of std_logic_vector(1 downto 0);
    type Heats_t is array(0 to 1611) of std_logic;
    
    
    constant STATE_Initial: std_logic_vector(1 downto 0) := "00";
    constant STATE_FROff: std_logic_vector(1 downto 0) := "01";
    constant STATE_FROn: std_logic_vector(1 downto 0) := "10";

end package FR_KripkeTypes2;

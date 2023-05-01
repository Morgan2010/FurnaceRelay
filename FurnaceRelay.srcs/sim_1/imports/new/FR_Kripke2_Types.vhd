----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05.03.2023 04:28:13
-- Design Name: 
-- Module Name: FR_Kripke2_Types - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

package FR_Kripke2_Types is

    type Initial_ReadSnapshot_t is record
        executeOnEntry: boolean;
        observed: boolean;
    end record Initial_ReadSnapshot_t;
    
    type Initial_ReadSnapshots_t is array(0 to 1) of Initial_ReadSnapshot_t;
    
    type Initial_WriteSnapshot_t is record
        executeOnEntry: boolean;
        observed: boolean;
    end record Initial_WriteSnapshot_t;
    
    type Initial_WriteSnapshots_t is array(0 to 1) of Initial_WriteSnapshot_t;
    
    type Initial_Ringlet_t is record
        read: Initial_ReadSnapshot_t;
        write: Initial_WriteSnapshot_t;
        observed: boolean;
    end record Initial_Ringlet_t;
    
    type Initial_Ringlets_t is array(0 to 1) of Initial_Ringlet_t;
    
    type Initial_Edge_t is record
        write: Initial_WriteSnapshot_t;
        nextState: std_logic_vector(1 downto 0);
        observed: boolean;
    end record Initial_Edge_t;
    
    type Initial_Edges_t is array (0 to 1) of Initial_Edge_t;

    type FROff_ReadSnapshot_t is record
        demand: std_logic_vector(1 downto 0);
        heat: std_logic;
        executeOnEntry: boolean;
        observed: boolean;
    end record FROff_ReadSnapshot_t;
    
    type FROff_ReadSnapshots_t is array(0 to 1457) of FROff_ReadSnapshot_t;
    
    type FROff_WriteSnapshot_t is record
        demand: std_logic_vector(1 downto 0);
        heat: std_logic;
        relayOn: std_logic;
        executeOnEntry: boolean;
        observed: boolean;
    end record FROff_WriteSnapshot_t;
    
    type FROff_WriteSnapshots_t is array(0 to 1457) of FROff_WriteSnapshot_t;
    
    type FROff_Ringlet_t is record
        read: FROff_ReadSnapshot_t;
        write: FROff_WriteSnapshot_t;
        observed: boolean;
    end record FROff_Ringlet_t;
    
    type FROff_Ringlets_t is array(0 to 1457) of FROff_Ringlet_t;
    
    type FROn_ReadSnapshot_t is record
        demand: std_logic_vector(1 downto 0);
        executeOnEntry: boolean;
        observed: boolean;
    end record FROn_ReadSnapshot_t;
    
    type FROn_ReadSnapshots_t is array(0 to 161) of FROn_ReadSnapshot_t;
    
    type FROn_WriteSnapshot_t is record
        demand: std_logic_vector(1 downto 0);
        relayOn: std_logic;
        executeOnEntry: boolean;
        observed: boolean;
    end record FROn_WriteSnapshot_t;
    
    type FROn_WriteSnapshots_t is array(0 to 161) of FROn_WriteSnapshot_t;
    
    type FROn_Ringlet_t is record
        read: FROn_ReadSnapshot_t;
        write: FROn_WriteSnapshot_t;
        observed: boolean;
    end record FROn_Ringlet_t;
    
    type FROn_Ringlets_t is array(0 to 161) of FROn_Ringlet_t;

    type TotalSnapshot_t is record
        demand: std_logic_vector(1 downto 0);
        heat: std_logic;
        relayOn: std_logic;
        fr_demand: std_logic_vector(1 downto 0);
        fr_heat: std_logic;
        currentState: std_logic_vector(1 downto 0);
        previousRinglet: std_logic_vector(1 downto 0);
        internalState: std_logic_vector(2 downto 0);
        internalStateOut: std_logic_vector(2 downto 0);
        currentStateOut: std_logic_vector(1 downto 0);
        targetStateIn: std_logic_vector(1 downto 0);
        targetStateOut: std_logic_vector(1 downto 0);
        executeOnEntry: boolean;
        observed: boolean;
    end record TotalSnapshot_t;
    
    type AllSnapshots_t is array (0 to 728) of TotalSnapshot_t;
    type DataStore_t is array(0 to 1611) of TotalSnapshot_t;
    type WriteSnapshotJobs_t is array(0 to 728) of TotalSnapshot_t;
    
    constant STATE_Initial: std_logic_vector(1 downto 0) := "00";
    constant STATE_FROff: std_logic_vector(1 downto 0) := "01";
    constant STATE_FROn: std_logic_vector(1 downto 0) := "10";
    
    constant CheckTransition: std_logic_vector(2 downto 0) := "000";
    constant Internal: std_logic_vector(2 downto 0) := "001";
    constant NoOnEntry: std_logic_vector(2 downto 0) := "010";
    constant OnEntry: std_logic_vector(2 downto 0) := "011";
    constant OnExit: std_logic_vector(2 downto 0) := "100";
    constant ReadSnapshot: std_logic_vector(2 downto 0) := "101";
    constant WriteSnapshot: std_logic_vector(2 downto 0) := "110";

end package FR_Kripke2_Types;

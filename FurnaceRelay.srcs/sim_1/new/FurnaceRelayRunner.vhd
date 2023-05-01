----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01.05.2023 21:12:08
-- Design Name: 
-- Module Name: FurnaceRelayRunner - Behavioral
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

entity FurnaceRelayRunner is
port (
    clk: in std_logic;
    internalStateIn: in std_logic_vector(2 downto 0);
    internalStateOut: out std_logic_vector(2 downto 0);
    currentStateIn: in std_logic_vector(1 downto 0);
    currentStateOut: out std_logic_vector(1 downto 0);
    previousRingletIn: in std_logic_vector(1 downto 0);
    previousRingletOut: out std_logic_vector(1 downto 0);
    targetStateIn: in std_logic_vector(1 downto 0);
    targetStateOut: out std_logic_vector(1 downto 0);
    demand: in std_logic_vector(1 downto 0);
    heat: in std_logic;
    relayOn: out std_logic;
    fr_demand: out std_logic_vector(1 downto 0);
    fr_heat: out std_logic;
    fr_relayOn: out std_logic;
    reset: in std_logic;
    goalInternalState: in std_logic_vector(2 downto 0);
    finished: out boolean := true
);
end FurnaceRelayRunner;

architecture Behavioral of FurnaceRelayRunner is

    signal stateTracker: std_logic_vector(1 downto 0) := "00";
    constant WaitToStart: std_logic_vector(1 downto 0) := "00";
    constant StartExecuting: std_logic_vector(1 downto 0) := "01";
    constant Executing: std_logic_vector(1 downto 0) := "10";
    signal internalState: std_logic_vector(2 downto 0);
    signal rst: std_logic := '1';
    signal setInternalSignals: std_logic := '0';
    signal goalInternal: std_logic_vector(2 downto 0);

    component FurnaceRelay is
        port(
            clk: in std_logic;
            EXTERNAL_demand: in std_logic_vector(1 downto 0);
            EXTERNAL_Heat: in std_logic := '0';
            EXTERNAL_RelayOn: out std_logic := '0';
            FurnaceRelay_demand: out std_logic_vector(1 downto 0);
            FurnaceRelay_heat: out std_logic;
            FurnaceRelay_currentStateIn: in std_logic_vector(1 downto 0);
            FurnaceRelay_previousRingletIn: in std_logic_vector(1 downto 0);
            FurnaceRelay_internalStateIn: in std_logic_vector(2 downto 0);
            FurnaceRelay_currentStateOut: out std_logic_vector(1 downto 0);
            FurnaceRelay_targetStateIn: in std_logic_vector(1 downto 0);
            FurnaceRelay_targetStateOut: out std_logic_vector(1 downto 0);
            FurnaceRelay_previousRingletOut: out std_logic_vector(1 downto 0);
            FurnaceRelay_internalStateOut: out std_logic_vector(2 downto 0);
            setInternalSignals: in std_logic;
            reset: in std_logic
        );
    end component;

begin

    fr_inst: FurnaceRelay port map(
        clk => clk,
        EXTERNAL_demand => demand,
        EXTERNAL_Heat => heat,
        EXTERNAL_RelayOn => relayOn,
        FurnaceRelay_demand => fr_demand,
        FurnaceRelay_heat => fr_heat,
        FurnaceRelay_currentStateIn => currentStateIn,
        FurnaceRelay_previousRingletIn => previousRingletIn,
        FurnaceRelay_internalStateIn => internalStateIn,
        FurnaceRelay_currentStateOut => currentStateOut,
        FurnaceRelay_targetStateIn => targetStateIn,
        FurnaceRelay_targetStateOut => targetStateOut,
        FurnaceRelay_previousRingletOut => previousringletOut,
        FurnaceRelay_internalStateOut => internalState,
        setInternalSignals => setInternalSignals,
        reset => rst
    );
    
    internalStateOut <= internalState;
    
process(clk)
begin
if rising_edge(clk) then
case stateTracker is
    when WaitToStart =>
        if reset = '1' then
            setInternalSignals <= '1';
            stateTracker <= StartExecuting;
            goalInternal <= goalInternalState;
        end if;
    when StartExecuting =>
        rst <= '0';
        setInternalSignals <= '0';
        stateTracker <= Executing;
        finished <= false;
    when Executing =>
        if internalState = goalInternalState then
            rst <= '1';
            finished <= true;
            stateTracker <= WaitToStart;
        end if;
    when others =>
        null;
end case;
end if;
end process;

end Behavioral;

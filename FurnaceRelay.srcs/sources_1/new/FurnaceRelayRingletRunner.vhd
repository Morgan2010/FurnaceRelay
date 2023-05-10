----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04.05.2023 04:40:57
-- Design Name: 
-- Module Name: FurnaceRelayRingletRunner - Behavioral
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
use work.FurnaceRelayTypes.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity FurnaceRelayRingletRunner is
port(
    clk: in std_logic;
    reset: in std_logic := '0';
    state: in std_logic_vector(1 downto 0) := "00";
    demand: in std_logic_vector(1 downto 0) := "00";
    heat: in std_logic := '0';
    relayOn: in std_logic;
    previousRinglet: in std_logic_vector(1 downto 0) := "ZZ";
    readSnapshotState: out ReadSnapshot_t;
    writeSnapshotState: out WriteSnapshot_t;
    nextState: out std_logic_vector(1 downto 0);
    finished: out boolean := true
);
end FurnaceRelayRingletRunner;

architecture Behavioral of FurnaceRelayRingletRunner is

    constant ReadSnapshot: std_logic_vector(2 downto 0) := "101";
    constant WriteSnapshot: std_logic_vector(2 downto 0) := "110";

    signal machine: TotalSnapshot_t := (
        demand => "00",
        heat => '0',
        relayOn => '0',
        fr_demand => "00",
        fr_heat => '0',
        fr_relayOn => 'U',
        fr_relayOnIn => 'U',
        currentStateIn => "00",
        currentStateOut => "00",
        previousRingletIn => "00",
        previousRingletOut => "00",
        internalStateIn => ReadSnapshot,
        internalStateOut => ReadSnapshot,
        targetStateIn => "00",
        targetStateOut => "00",
        reset => '0',
        goalInternalState => WriteSnapshot,
        finished => true,
        executeOnEntry => true,
        observed => false
    );

    signal tracker: std_logic_vector(1 downto 0) := "00";
    constant WaitForStart: std_logic_vector(1 downto 0) := "00";
    constant Executing: std_logic_vector(1 downto 0) := "01";
    constant WaitForMachineStart: std_logic_vector(1 downto 0) := "10";
    constant WaitForFinish: std_logic_vector(1 downto 0) := "11";
    signal currentState: std_logic_vector(1 downto 0) := "00";
    
    component FurnaceRelayMachineRunner is
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
        fr_relayOnIn: in std_logic;
        reset: in std_logic;
        goalInternalState: in std_logic_vector(2 downto 0);
        finished: out boolean
    );
    end component;

begin

run_inst: FurnaceRelayMachineRunner port map(
    clk => clk,
    internalStateIn => machine.internalStateIn,
    internalStateOut => machine.internalStateOut,
    currentStateIn => machine.currentStateIn,
    currentStateOut => machine.currentStateOut,
    previousRingletIn => machine.previousRingletIn,
    previousRingletOut => machine.previousringletOut,
    targetStateIn => machine.targetStateIn,
    targetStateOut => machine.targetStateOut,
    demand => machine.demand,
    heat => machine.heat,
    relayOn => machine.relayOn,
    fr_demand => machine.fr_demand,
    fr_heat => machine.fr_heat,
    fr_relayOn => machine.fr_relayOn,
    fr_relayOnIn => machine.fr_relayOnIn,
    reset => machine.reset,
    goalInternalState => machine.goalInternalState,
    finished => machine.finished
);

process(clk)
begin
if rising_edge(clk) then
case tracker is
    when WaitForStart =>
        if reset = '1' then
            tracker <= WaitForMachineStart;
            machine.reset <= '1';
            readSnapshotState <= (
                demand => demand,
                heat => heat,
                state => state,
                fr_relayOn => relayOn,
                executeOnEntry => previousRinglet /= state
            );
            finished <= false;
        else
            machine.demand <= demand;
            machine.heat <= heat;
            machine.currentStateIn <= state;
            machine.internalStateIn <= ReadSnapshot;
            machine.targetStateIn <= state;
            machine.reset <= '0';
            machine.goalInternalState <= WriteSnapshot;
            machine.previousRingletIn <= previousRinglet;
            machine.fr_relayOnIn <= relayOn;
        end if;
        currentState <= state;
    when WaitForMachineStart =>
        machine.reset <= '1';
        tracker <= Executing;
    when Executing =>
        machine.reset <= '1';
        if machine.finished then
            writeSnapshotState <= (
                demand => machine.fr_demand,
                heat => machine.fr_heat,
                relayOn => machine.fr_relayOn,
                state => currentState,
                nextState => machine.currentStateOut,
                executeOnEntry => machine.currentStateOut /= currentState
            );
            nextState <= machine.currentStateOut;
            finished <= true;
            tracker <= WaitForFinish;
        end if;
    when WaitForFinish =>
        if reset = '0' then
            machine.reset <= '0';
            tracker <= WaitForStart;
        end if;
    when others =>
        null;
end case;
end if;
end process;

end Behavioral;

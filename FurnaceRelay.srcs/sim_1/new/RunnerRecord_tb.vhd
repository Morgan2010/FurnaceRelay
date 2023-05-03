----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04.05.2023 00:58:27
-- Design Name: 
-- Module Name: RunnerRecord_tb - Behavioral
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
use work.FR_KripkeTypes2.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity RunnerRecord_tb is
--  Port ( );
end RunnerRecord_tb;

architecture Behavioral of RunnerRecord_tb is

    constant CheckTransition: std_logic_vector(2 downto 0) := "000";
    constant Internal: std_logic_vector(2 downto 0) := "001";
    constant NoOnEntry: std_logic_vector(2 downto 0) := "010";
    constant OnEntry: std_logic_vector(2 downto 0) := "011";
    constant OnExit: std_logic_vector(2 downto 0) := "100";
    constant ReadSnapshot: std_logic_vector(2 downto 0) := "101";
    constant WriteSnapshot: std_logic_vector(2 downto 0) := "110";

    signal clk: std_logic := '0';
    signal hasStarted: boolean := false;
    
    signal data: TotalSnapshot_t := (
        demand => "00",
        heat => '0',
        relayOn => '0',
        fr_demand => "00",
        fr_heat => '0',
        currentStateIn => "00",
        currentStateOut => "00",
        previousRingletIn => "ZZ",
        previousRingletOut => "ZZ",
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
    
    component FurnaceRelayRunner is
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
        reset: in std_logic;
        goalInternalState: in std_logic_vector(2 downto 0);
        finished: out boolean
    );
    end component;

begin

clk <= not clk after 10 ns;

run_inst: FurnaceRelayRunner port map(
    clk => clk,
    internalStateIn => data.internalStateIn,
    internalStateOut => data.internalStateOut,
    currentStateIn => data.currentStateIn,
    currentStateOut => data.currentStateOut,
    previousRingletIn => data.previousRingletIn,
    previousRingletOut => data.previousringletOut,
    targetStateIn => data.targetStateIn,
    targetStateOut => data.targetStateOut,
    demand => data.demand,
    heat => data.heat,
    relayOn => data.relayOn,
    fr_demand => data.fr_demand,
    fr_heat => data.fr_heat,
    reset => data.reset,
    goalInternalState => data.goalInternalState,
    finished => data.finished
);

process(clk)
begin
if (rising_edge(clk)) then
    if hasStarted then
        if data.finished then
            if data.internalStateOut = ReadSnapshot then
                data.currentStateIn <= data.currentStateOut;
                data.previousRingletIn <= data.previousRingletOut;
                data.targetStateIn <= data.targetStateOut;
                data.internalStateIn <= data.internalStateOut;
                data.goalInternalState <= WriteSnapshot;
                if data.currentStateOut = "01" then
                    data.demand <= "10";
                    data.heat <= '1';
                else
                    data.demand <= "01";
                    data.heat <= '0';
                end if;
            else
                data.goalInternalState <= ReadSnapshot;
            end if;
            data.reset <= '0';
        else
            data.reset <= '1';
        end if;
    else
        data.demand <= "00";
        data.heat <= '0';
        data.currentStateIn <= "00";
        data.previousRingletIn <= "ZZ";
        data.internalStateIn <= ReadSnapshot;
        data.targetStateIn <= "00";
        data.observed <= true;
        data.executeOnEntry <= true;
        data.reset <= '0';
        hasStarted <= data.finished;
        data.goalInternalState <= WriteSnapshot;
    end if;
end if;
end process;

end Behavioral;

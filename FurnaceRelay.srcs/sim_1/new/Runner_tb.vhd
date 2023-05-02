----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03.05.2023 03:22:45
-- Design Name: 
-- Module Name: Runner_tb - Behavioral
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

entity Runner_tb is
--  Port ( );
end Runner_tb;

architecture Behavioral of Runner_tb is

    constant CheckTransition: std_logic_vector(2 downto 0) := "000";
    constant Internal: std_logic_vector(2 downto 0) := "001";
    constant NoOnEntry: std_logic_vector(2 downto 0) := "010";
    constant OnEntry: std_logic_vector(2 downto 0) := "011";
    constant OnExit: std_logic_vector(2 downto 0) := "100";
    constant ReadSnapshot: std_logic_vector(2 downto 0) := "101";
    constant WriteSnapshot: std_logic_vector(2 downto 0) := "110";

    signal clk: std_logic := '0';
    signal internalStateIn: std_logic_vector(2 downto 0) := ReadSnapshot;
    signal internalStateOut: std_logic_vector(2 downto 0) := ReadSnapshot;
    signal currentStateIn: std_logic_vector(1 downto 0) := "00";
    signal currentStateOut: std_logic_vector(1 downto 0) := "00";
    signal previousRingletIn: std_logic_vector(1 downto 0) := "ZZ";
    signal previousRingletOut: std_logic_vector(1 downto 0) := "ZZ";
    signal targetStateIn: std_logic_vector(1 downto 0) := "00";
    signal targetStateOut: std_logic_vector(1 downto 0) := "00";
    signal demand: std_logic_vector(1 downto 0) := "00";
    signal heat: std_logic := '0';
    signal relayOn: std_logic;
    signal fr_demand: std_logic_vector(1 downto 0);
    signal fr_heat: std_logic;
    signal reset: std_logic := '0';
    signal goalInternalState: std_logic_vector(2 downto 0) := WriteSnapshot;
    signal finished: boolean;
    signal hasStarted: boolean := false;
    
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
    internalStateIn => internalStateIn,
    internalStateOut => internalStateOut,
    currentStateIn => currentStateIn,
    currentStateOut => currentStateOut,
    previousRingletIn => previousRingletIn,
    previousRingletOut => previousringletOut,
    targetStateIn => targetStateIn,
    targetStateOut => targetStateOut,
    demand => demand,
    heat => heat,
    relayOn => relayOn,
    fr_demand => fr_demand,
    fr_heat => fr_heat,
    reset => reset,
    goalInternalState => goalInternalState,
    finished => finished
);

process(clk)
begin
if (rising_edge(clk)) then
    if hasStarted then
        if finished then
            if internalStateIn = ReadSnapshot then
                currentStateIn <= currentStateOut;
                previousRingletIn <= previousRingletOut;
                targetStateIn <= targetStateOut;
                internalStateIn <= internalStateOut;
                goalInternalState <= WriteSnapshot;
            else
                goalInternalState <= ReadSnapshot;
            end if;
            reset <= '0';
        else
            reset <= '1';
        end if;
    else
        reset <= '1';
        hasStarted <= true;
    end if;
end if;
end process;

end Behavioral;

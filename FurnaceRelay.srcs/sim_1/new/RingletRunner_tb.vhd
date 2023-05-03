----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04.05.2023 05:12:15
-- Design Name: 
-- Module Name: RingletRunner_tb - Behavioral
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

entity RingletRunner_tb is
--  Port ( );
end RingletRunner_tb;

architecture Behavioral of RingletRunner_tb is

    signal clk: std_logic := '0';
    signal reset: std_logic := '0';
    signal state: std_logic_vector(1 downto 0) := "00";
    signal demand: std_logic_vector(1 downto 0) := "00";
    signal heat: std_logic := '0';
    signal previousRinglet: std_logic_vector(1 downto 0) := "ZZ";
    signal readSnapshotState: ReadSnapshot_t;
    signal writeSnapshotState: WriteSnapshot_t;
    signal nextState: std_logic_vector(1 downto 0) := "00";
    signal finished: boolean := true;
    
    signal tracker: std_logic_vector(1 downto 0) := "00";
    constant Initialisation: std_logic_vector(1 downto 0) := "00";
    constant StartExecuting: std_logic_vector(1 downto 0) := "01";
    constant WaitForFinish: std_logic_vector(1 downto 0) := "10";
    constant WaitForStart: std_logic_vector(1 downto 0) := "11";
    
    component RingletRunner is
    port(
        clk: in std_logic;
        reset: in std_logic := '0';
        state: in std_logic_vector(1 downto 0) := "00";
        demand: in std_logic_vector(1 downto 0) := "00";
        heat: in std_logic := '0';
        previousRinglet: in std_logic_vector(1 downto 0) := "ZZ";
        readSnapshotState: out ReadSnapshot_t;
        writeSnapshotState: out WriteSnapshot_t;
        nextState: out std_logic_vector(1 downto 0);
        finished: out boolean := true
    );
    end component;

begin

clk <= not clk after 10ns;

run_inst: RingletRunner port map(
    clk => clk,
    reset => reset,
    state => state,
    demand => demand,
    heat => heat,
    previousRinglet => previousRinglet,
    readSnapshotState => readSnapshotState,
    writeSnapshotState => writeSnapshotState,
    nextState => nextState,
    finished => finished
);

process(clk)
begin
if rising_edge(clk) then
    case tracker is
        when Initialisation =>
            reset <= '0';
            tracker <= StartExecuting;
        when StartExecuting =>
            reset <= '1';
            tracker <= WaitForStart;
        when WaitForStart =>
            tracker <= WaitForFinish;
        when WaitForFinish =>
            reset <= '0';
            if finished then
                state <= nextState;
                previousRinglet <= state;
                tracker <= StartExecuting;
            end if;
        when others =>
            null;
    end case;
end if;
end process;

end Behavioral;

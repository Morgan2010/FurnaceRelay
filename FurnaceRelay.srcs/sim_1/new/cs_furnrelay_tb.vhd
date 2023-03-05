----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01.03.2023 03:29:06
-- Design Name: 
-- Module Name: cs_furnrelay_tb - Behavioral
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

entity cs_furnrelay_tb is
--  Port ( );
end cs_furnrelay_tb;

architecture Behavioral of cs_furnrelay_tb is

    signal clk: std_logic := '0';

    signal state: std_logic_vector(2 downto 0) := "000";
    
    signal demand: std_logic := '0';
    
    signal switch: std_logic_vector(2 downto 0) := "000";
    
    signal instate: std_logic_vector(2 downto 0) := state;

    component cs_furnrelay is
        port(
            state: inout std_logic_vector(2 downto 0);
            demand: in std_logic;
            ins_seasonswitch: in std_logic_vector(2 downto 0);
            instate: inout std_logic_vector(2 downto 0)
        );
    end component;

begin

    cs_inst: cs_furnrelay port map(
        state => state,
        demand => demand,
        ins_seasonswitch => switch,
        instate => instate
    );

demand <= not demand after 10 ns;

clk <= not clk after 10 ns;

process(clk)
begin
    if rising_edge(clk) and state = "000" then
        state <= "100";
    end if;
end process;

end Behavioral;

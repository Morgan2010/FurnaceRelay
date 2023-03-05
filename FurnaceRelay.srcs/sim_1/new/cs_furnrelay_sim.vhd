----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 26.02.2023 09:10:49
-- Design Name: 
-- Module Name: cs_furnrelay_sim - Behavioral
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

use work.cs_furnrelay_kripke.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity cs_furnrelay_sim is
--  Port ( );
end cs_furnrelay_sim;

architecture Behavioral of cs_furnrelay_sim is

    signal clk: std_logic := '0';
    
    signal state: std_logic_vector(2 downto 0);
    signal demand: std_logic;
    signal ins_seasonswitch: std_logic_vector(2 downto 0);
    signal instate: std_logic_vector(2 downto 0);
    
    type cache_t is array(0 to 1023) of cs_KripkeState;
    type queue_t is array(0 to 63) of cs_KripkeState;
    type states_t is array(0 to 63) of std_logic_vector(2 downto 0);
    type demand_t is array(0 to 63) of std_logic;
    type stdLogicTypes_t is array(0 to 8) of std_logic;
    constant stdLogicTypes: stdLogicTypes_t := (
        0 => 'U',
        1 => 'X',
        2 => '0',
        3 => '1',
        4 => 'Z',
        5 => 'W',
        6 => 'L',
        7 => 'H',
        8 => '-'
    );
    
    signal cache: cache_t;
    signal queue: queue_t;

    signal states: states_t;
    signal demands: demand_t;
    signal switches: states_t;
    signal instates: states_t;

    component cs_furnrelay is
        port(
            state: inout std_logic_vector(2 downto 0);
            demand: in std_logic;
            ins_seasonswitch: in std_logic_vector(2 downto 0);
            instate: inout std_logic_vector(2 downto 0)
        );
    end component;

begin

    cs: for i in 0 to 63 generate
        inst: cs_furnrelay port map (
            state => states(i),
            demand => demands(i),
            ins_seasonswitch => switches(i),
            instate => instates(i)
        );
    end generate;

clk <= not clk after 10 ns;

--process(clk)
--    if rising_edge(clk) then
        
--    end if;
--begin

--end process;

end Behavioral;














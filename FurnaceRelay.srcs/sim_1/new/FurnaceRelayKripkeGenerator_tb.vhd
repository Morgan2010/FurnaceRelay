----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07.05.2023 23:21:37
-- Design Name: 
-- Module Name: FurnaceRelayKripkeGenerator_tb - Behavioral
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

entity FurnaceRelayKripkeGenerator_tb is
--  Port ( );
end FurnaceRelayKripkeGenerator_tb;

architecture Behavioral of FurnaceRelayKripkeGenerator_tb is

    signal clk: std_logic := '0';
    signal initialRinglets: Initial_Ringlets_t;
    signal frOffRinglets: FROff_Ringlets_t;
    signal frOnRinglets: FROn_Ringlets_t;
    signal completed: std_logic;
    
    component FurnaceRelayKripkeGenerator is
    port(
        clk: in std_logic;
        initialRinglets: out Initial_Ringlets_t;
        frOffRinglets: out FROff_Ringlets_t;
        frOnRinglets: out FROn_Ringlets_t;
        completed: out std_logic := '0'
    );
    end component;

begin


clk <= not clk after 4 ns; -- 125MHz clock.

fr_inst: FurnaceRelayKripkeGenerator port map(
    clk =>clk,
    initialRinglets => initialRinglets,
    frOffRinglets => frOffRinglets,
    frOnRinglets => frOnRinglets,
    completed => completed
);

end Behavioral;

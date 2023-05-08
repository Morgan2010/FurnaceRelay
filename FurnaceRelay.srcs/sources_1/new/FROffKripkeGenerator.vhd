----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08.05.2023 17:23:46
-- Design Name: 
-- Module Name: FROffKripkeGenerator - Behavioral
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

entity FROffKripkeGenerator is
port(
    clk: in std_logic;
    readSnapshot: in ReadSnapshot_t;
    writeSnapshot: in WriteSnapshot_t;
    ringlet: out FROff_Ringlet_t;
    pendingState: out ObservedState_t
);
end FROffKripkeGenerator;

architecture Behavioral of FROffKripkeGenerator is

begin

process(clk)
begin
if rising_edge(clk) then
    ringlet <= (
        readSnapshot => (
            demand => readSnapshot.demand,
            heat => readSnapshot.heat,
            executeOnEntry => readSnapshot.executeOnEntry
        ),
        writeSnapshot => (
            relayOn => writeSnapshot.relayOn,
            nextState => writeSnapshot.nextState,
            executeOnEntry => writeSnapshot.executeOnEntry
        ),
        observed => true
    );
    pendingState <= (
        state => writeSnapshot.nextState,
        executeOnEntry => writeSnapshot.executeOnEntry,
        observed => true
    );
end if;
end process;

end Behavioral;

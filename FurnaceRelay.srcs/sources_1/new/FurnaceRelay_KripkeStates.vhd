library IEEE;
use IEEE.std_logic_1164.all;

package FurnaceRelay_KripkeStates is
    type FurnaceRelay_STATE_FROff_Read is record
        EXTERNAL_demand: std_logic_vector(1 downto 0);
        EXTERNAL_Heat: std_logic;
    end record FurnaceRelay_STATE_FROff_Read;
    type FurnaceRelay_STATE_FROn_Read is record
        EXTERNAL_demand: std_logic_vector(1 downto 0);
    end record FurnaceRelay_STATE_FROn_Read;
    type FurnaceRelay_STATE_FROff_Write is record
        EXTERNAL_RelayOn: std_logic;
    end record FurnaceRelay_STATE_FROff_Write;
    type FurnaceRelay_STATE_FROn_Write is record
        EXTERNAL_RelayOn: std_logic;
    end record FurnaceRelay_STATE_FROn_Write;
end package FurnaceRelay_KripkeStates;

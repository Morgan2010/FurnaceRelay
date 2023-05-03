----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04.05.2023 01:03:13
-- Design Name: 
-- Module Name: FR_KripkeTypes2 - Behavioral
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

package FR_KripkeTypes2 is

    type TotalSnapshot_t is record
        demand: std_logic_vector(1 downto 0);
        heat: std_logic;
        relayOn: std_logic;
        fr_demand: std_logic_vector(1 downto 0);
        fr_heat: std_logic;
        currentStateIn: std_logic_vector(1 downto 0);
        currentStateOut: std_logic_vector(1 downto 0);
        previousRingletIn: std_logic_vector(1 downto 0);
        previousRingletOut: std_logic_vector(1 downto 0);
        internalStateIn: std_logic_vector(2 downto 0);
        internalStateOut: std_logic_vector(2 downto 0);
        targetStateIn: std_logic_vector(1 downto 0);
        targetStateOut: std_logic_vector(1 downto 0);
        reset: std_logic;
        goalInternalState: std_logic_vector(2 downto 0);
        finished: boolean;
        executeOnEntry: boolean;
        observed: boolean;
    end record TotalSnapshot_t;

end package FR_KripkeTypes2;

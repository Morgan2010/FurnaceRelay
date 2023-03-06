----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05.03.2023 04:25:30
-- Design Name: 
-- Module Name: FR_Kripke2 - Behavioral
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
use work.FR_Kripke2_Types.all;
use work.KripkePrimitiveTypes.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;



entity FR_Kripke2 is
--  Port ( );
end FR_Kripke2;

architecture Behavioral of FR_Kripke2 is
    signal clk: std_logic := '0';
    signal workingBuffer: DataStore_t;
    signal allJobs: DataStore_t := (
        others => (
            demand => "UU",
            heat => 'U',
            relayOn => 'U',
            fr_demand => "UU",
            fr_heat => 'U',
            currentState => STATE_Initial,
            previousRinglet => "ZZ",
            internalState => ReadSnapshot,
            executeOnEntry => true,
            observed => false
        )
    );
    signal currentJobs: DataStore_t := (
        others => (
            demand => "UU",
            heat => 'U',
            relayOn => 'U',
            fr_demand => "UU",
            fr_heat => 'U',
            currentState => STATE_Initial,
            previousRinglet => "ZZ",
            internalState => ReadSnapshot,
            executeOnEntry => true,
            observed => false
        )
    );
    signal writeSnapshotJobs: DataStore_t;
    signal reset: std_logic := '0';
    signal internalState: std_logic_vector(2 downto 0);
    
    signal initialReadsnapshots: Initial_ReadSnapshots_t;
    signal frOffReadSnapshots: FROff_ReadSnapshots_t;
    signal frOnReadSnapshots: FROn_ReadSnapshots_t;
    
    signal initialWriteSnapshots: Initial_WriteSnapshots_t;
    signal frOffWriteSnapshots: FROff_WriteSnapshots_t;
    signal frOnWriteSnapshots: FROn_WriteSnapshots_t;
    
    signal initialRinglets: Initial_Ringlets_t;
    signal frOffRinglets: FROff_Ringlets_t;
    signal frOnRinglets: FROn_Ringlets_t;
    
    signal initialEdges: Initial_Edges_t;

    constant Initialisation: std_logic_vector(3 downto 0) := (others => '0');
    constant GenerateWorkingJob: std_logic_vector(3 downto 0) := x"1";
    constant Finished: std_logic_vector(3 downto 0) := x"2";
    constant ExecuteReadSnapshot: std_logic_vector(3 downto 0) := x"3";
    constant WaitForWriteSnapshot: std_logic_vector(3 downto 0) := x"4";
    constant CalculateEdgeSetup: std_logic_vector(3 downto 0) := x"5";
    constant SetWriteSnapshotJobs: std_logic_vector(3 downto 0) := x"6";
    constant CalculateEdge: std_logic_vector(3 downto 0) := x"7";
    constant Error: std_logic_vector(3 downto 0) := x"8";
    signal stateTracker: std_logic_vector(3 downto 0) := Initialisation;
    signal lastIndexSaved: natural := 0;
    signal snapshotTracker: integer range 0 to 1611 := 0;
    signal skippedJobsSaved: natural := 0;
    

    component FurnaceRelay is
        port(
            clk: in std_logic;
            EXTERNAL_demand: in std_logic_vector(1 downto 0);
            EXTERNAL_Heat: in std_logic := '0';
            EXTERNAL_RelayOn: out std_logic := '0';
            FurnaceRelay_demand: out std_logic_vector(1 downto 0);
            FurnaceRelay_heat: out std_logic;
            FurnaceRelay_currentStateIn: in std_logic_vector(1 downto 0);
            FurnaceRelay_previousRingletIn: in std_logic_vector(1 downto 0);
            FurnaceRelay_internalStateIn: in std_logic_vector(2 downto 0);
            FurnaceRelay_currentStateOut: out std_logic_vector(1 downto 0);
            FurnaceRelay_previousRingletOut: out std_logic_vector(1 downto 0);
            FurnaceRelay_internalStateOut: out std_logic_vector(2 downto 0);
            reset: in std_logic
        );
    end component;

begin

    fr_gen: for i in 0 to 1457 generate
        fr_inst: FurnaceRelay port map(
            clk => clk,
            EXTERNAL_demand => currentJobs(i).demand,
            External_Heat => currentJobs(i).heat,
            EXTERNAL_RelayOn => currentJobs(i).relayOn,
            FurnaceRelay_demand => currentJobs(i).fr_demand,
            FurnaceRelay_heat => currentJobs(i).fr_heat,
            FurnaceRelay_currentStateIn => currentJobs(i).currentState,
            FurnaceRelay_previousRingletIn => currentJobs(i).previousRinglet,
            FurnaceRelay_internalStateIn => currentJobs(i).internalState,
            FurnaceRelay_internalStateOut => internalState,
            reset => reset
        );
    end generate fr_gen;

clk <= not clk after 10 ns;

process(clk)
variable lastIndex: natural := 0;
variable skippedJobs: natural := 0;
variable skippedWrites: natural := 0;
variable hasError: boolean := false;
begin
if rising_edge(clk) then
    case stateTracker is
        when Initialisation =>
            reset <= '0';
            for i in 0 to 8 loop
                for j in 0 to 8 loop
                    for k in 0 to 8 loop
                        allJobs(i * 81 + j * 9 + k) <= (
                            demand => (1 => stdLogicTypes(i), 0 => stdLogicTypes(j)),
                            heat => stdLogicTypes(k),
                            relayOn => '0',
                            fr_demand => (1 => stdLogicTypes(i), 0 => stdLogicTypes(j)),
                            fr_heat => stdLogicTypes(k),
                            currentState => STATE_Initial,
                            previousRinglet => "ZZ",
                            internalState => ReadSnapshot,
                            executeOnEntry => true,
                            observed => true
                        );
                    end loop;
                end loop;
            end loop;
            stateTracker <= GenerateWorkingJob;
        when GenerateWorkingJob =>
            reset <= '0';
            if allJobs(0).observed = false and writeSnapshotJobs(0).observed = false then
                stateTracker <= Finished;
            elsif allJobs(0).observed = false then
                lastIndex := 0;
                skippedJobs := 0;
                stateTracker <= CalculateEdgeSetup;
            else
                lastIndex := 0;
                skippedJobs := 0;
                for i in 0 to 1611 loop
                    if allJobs(i).observed then
                        lastIndex := i;
                        case allJobs(i).currentState is
                            when STATE_Initial =>
                                s_loop: for s in 0 to 1 loop
                                    if initialReadSnapshots(s).observed and (initialReadSnapshots(s).executeOnEntry = (allJobs(i).currentState /= allJobs(i).previousRinglet)) then
                                        skippedJobs := skippedJobs + 1;
                                        exit s_loop;
                                    elsif initialReadSnapshots(s).observed = false then
                                        initialReadSnapshots(s) <= (
                                            executeOnEntry => (allJobs(i).currentState /= allJobs(i).previousRinglet),
                                            observed => true
                                        );
                                        currentJobs(i - skippedJobs).demand <= allJobs(i).demand;
                                        currentJobs(i - skippedJobs).heat <= allJobs(i).heat;
                                        currentJobs(i - skippedJobs).currentState <= allJobs(i).currentState;
                                        currentJobs(i - skippedJobs).previousRinglet <= allJobs(i).previousRinglet;
                                        currentJobs(i - skippedJobs).executeOnEntry <= (allJobs(i).currentState /= allJobs(i).previousRinglet);
                                        currentJobs(i - skippedJobs).observed <= true;
                                        exit s_loop;
                                    elsif s = 1 and initialReadSnapshots(s).observed = true then
                                        hasError := true;
                                    end if;
                                end loop s_loop;
                            when STATE_FROff =>
                                s_loop2: for s in 0 to 1457 loop
                                    if frOffReadSnapshots(s).observed and frOffReadSnapshots(s).demand = allJobs(i).demand and frOffReadSnapshots(s).heat = allJobs(i).heat and (frOffReadSnapshots(s).executeOnEntry = (allJobs(i).currentState /= allJobs(i).previousRinglet)) then
                                        skippedJobs := skippedJobs + 1;
                                        exit s_loop2;
                                    elsif frOffReadSnapshots(s).observed = false then
                                        frOffReadSnapshots(s) <= (
                                            demand => allJobs(i).demand,
                                            heat => allJobs(i).heat,
                                            executeOnEntry => (allJobs(i).currentState /= allJobs(i).previousRinglet),
                                            observed => true
                                        );
                                        currentJobs(i - skippedJobs).demand <= allJobs(i).demand;
                                        currentJobs(i - skippedJobs).heat <= allJobs(i).heat;
                                        currentJobs(i - skippedJobs).currentState <= allJobs(i).currentState;
                                        currentJobs(i - skippedJobs).previousRinglet <= allJobs(i).previousRinglet;
                                        currentJobs(i - skippedJobs).executeOnEntry <= (allJobs(i).currentState /= allJobs(i).previousRinglet);
                                        currentJobs(i - skippedJobs).observed <= true;
                                        exit s_loop2;
                                    elsif s = 1457 and frOffReadSnapshots(s).observed = true then
                                        hasError := true;
                                    end if;
                                end loop s_loop2;
                            when STATE_FROn =>
                                s_loop3: for s in 0 to 161 loop
                                    if frOnReadSnapshots(s).observed and frOnReadSnapshots(s).demand = allJobs(i).demand and (frOnReadSnapshots(s).executeOnEntry = (allJobs(i).currentState /= allJobs(i).previousRinglet)) then
                                        skippedJobs := skippedJobs + 1;
                                        exit s_loop3;
                                    elsif frOnReadSnapshots(s).observed = false then
                                        frOnReadSnapshots(s) <= (
                                            demand => allJobs(i).demand,
                                            executeOnEntry => (allJobs(i).currentState /= allJobs(i).previousRinglet),
                                            observed => true
                                        );
                                        currentJobs(i - skippedJobs).demand <= allJobs(i).demand;
                                        currentJobs(i - skippedJobs).heat <= allJobs(i).heat;
                                        currentJobs(i - skippedJobs).currentState <= allJobs(i).currentState;
                                        currentJobs(i - skippedJobs).previousRinglet <= allJobs(i).previousRinglet;
                                        currentJobs(i - skippedJobs).executeOnEntry <= (allJobs(i).currentState /= allJobs(i).previousRinglet);
                                        currentJobs(i - skippedJobs).observed <= true;
                                        exit s_loop3;
                                    elsif s = 161 and frOnReadSnapshots(s).observed = true then
                                        hasError := true;
                                    end if;
                                end loop s_loop3;
                            when others =>
                                null;
                        end case;
                        allJobs(i).observed <= false;
                    end if;
                end loop;
                for i in 0 to 1611 loop
                    currentJobs(i).internalState <= ReadSnapshot;
                end loop;
                if hasError then
                    stateTracker <= Error;
                else
                    stateTracker <= ExecuteReadSnapshot;
                end if;
            end if;
            lastIndexSaved <= lastIndex;
            skippedJobsSaved <= skippedJobs;
        when ExecuteReadSnapshot =>
            if currentJobs(0).observed = false then
                reset <= '0';
                for i in 0 to 1611 loop
                    currentJobs(i).internalState <= WriteSnapshot;
                end loop;
                stateTracker <= CalculateEdgeSetup;
            else
                reset <= '1';
                stateTracker <= WaitForWriteSnapshot;
            end if;
        when WaitForWriteSnapshot =>
            if internalState = WriteSnapshot then
                reset <= '0';
                skippedWrites := 0;
                for i in 0 to (lastIndex - skippedJobs) loop
                    case currentJobs(i).currentState is
                        when STATE_Initial =>
                            for r in 0 to 1 loop
                                if initialRinglets(r).observed = false then
                                    initialRinglets(r) <= (
                                        read => (executeOnEntry => currentJobs(i).executeOnEntry, observed => true),
                                        write => (executeOnEntry => currentJobs(i).executeOnEntry, observed => true),
                                        observed => true
                                    );
                                    exit;
                                end if;
                            end loop;
                            for w in 0 to 1 loop
                                if initialWriteSnapshots(w).observed = true and initialWriteSnapshots(w).executeOnEntry = currentJobs(i).executeOnEntry then
                                    skippedWrites := skippedWrites + 1;
                                    exit;
                                elsif initialWriteSnapshots(w).observed = false then
                                    initialWriteSnapshots(w) <= (executeOnEntry => currentJobs(i).executeOnentry, observed => true);
                                    writeSnapshotJobs(i - skippedWrites) <= currentJobs(i);
                                elsif w = 1 and initialWriteSnapshots(w).observed = true then
                                    hasError := true;
                                end if;
                            end loop;
                        when STATE_FROff =>
                            for r in 0 to 1457 loop
                                if frOffRinglets(r).observed = false then
                                    frOffRinglets(r) <= (
                                        read => (
                                            demand => currentJobs(i).demand,
                                            heat => currentJobs(i).heat,
                                            executeOnEntry => currentJobs(i).executeOnEntry,
                                            observed => true
                                        ),
                                        write => (
                                            demand => currentJobs(i).fr_demand,
                                            heat => currentJobs(i).fr_heat,
                                            relayOn => currentJobs(i).relayOn,
                                            executeOnEntry => currentJobs(i).executeOnEntry,
                                            observed => true
                                        ),
                                        observed => true
                                    );
                                    exit;
                                end if;
                            end loop;
                            for w in 0 to 1457 loop
                                if frOffWriteSnapshots(w).demand = currentJobs(i).fr_demand and frOffWriteSnapshots(w).heat = currentJobs(i).fr_heat and frOffWriteSnapshots(w).relayOn = currentJobs(i).relayOn and frOffWriteSnapshots(w).executeOnEntry = currentJobs(i).executeOnEntry and frOffWriteSnapshots(w).observed = true then
                                    skippedWrites := skippedWrites + 1;
                                    exit;
                                elsif frOffWriteSnapshots(w).observed = false then
                                    frOffWriteSnapshots(w) <= (
                                        demand => currentJobs(i).fr_demand,
                                        heat => currentJobs(i).fr_heat,
                                        relayOn => currentJobs(i).relayOn,
                                        executeOnEntry => currentJobs(i).executeOnEntry,
                                        observed => true
                                    );
                                    writeSnapshotJobs(i - skippedWrites) <= currentJobs(i);
                                elsif w = 1457 and frOffWriteSnapshots(w).observed = true then
                                    hasError := true;
                                end if;
                            end loop;
                        when STATE_FROn =>
                            for r in 0 to 161 loop
                                if frOnRinglets(r).observed = false then
                                    frOnRinglets(r) <= (
                                        read => (
                                            demand => currentJobs(i).demand,
                                            executeOnEntry => currentJobs(i).executeOnEntry,
                                            observed => true
                                        ),
                                        write => (
                                            demand => currentJobs(i).fr_demand,
                                            relayOn => currentJobs(i).relayOn,
                                            executeOnEntry => currentJobs(i).executeOnEntry,
                                            observed => true
                                        ),
                                        observed => true
                                    );
                                    exit;
                                end if;
                            end loop;
                            for w in 0 to 161 loop
                                if frOnWriteSnapshots(w).demand = currentJobs(i).fr_demand and frOnWriteSnapshots(w).relayOn = currentJobs(i).relayOn and frOnWriteSnapshots(w).observed = true and frOnWriteSnapshots(w).executeOnEntry = currentJobs(i).executeOnEntry then
                                    skippedWrites := skippedWrites + 1;
                                    exit;
                                elsif frOnWriteSnapshots(w).observed = false then
                                    frOnWriteSnapshots(w) <= (demand => currentJobs(i).fr_demand, relayOn => currentJobs(i).relayOn, executeOnEntry => currentJobs(i).executeOnEntry, observed => true);
                                    writeSnapshotJobs(i - skippedWrites) <= currentJobs(i);
                                elsif w = 161 and frOnWriteSnapshots(w).observed = true then
                                    hasError := true;
                                end if;
                            end loop;
                        when others =>
                            null;
                    end case;
                end loop;
                if hasError then
                    stateTracker <= Error;
                else
                    stateTracker <= CalculateEdgeSetup;
                end if;
            end if;
        when CalculateEdgeSetup =>
            if writeSnapshotJobs(0).observed = false then
                stateTracker <= GenerateWorkingJob;
            else
                snapshotTracker <= 0;
                stateTracker <= SetWriteSnapshotJobs;
                skippedJobs := 0;
            end if;
        when SetWriteSnapshotJobs =>
            if writeSnapshotJobs(snapshotTracker).observed = false then
                stateTracker <= GenerateWorkingJob;
                snapshotTracker <= 0;
            else
                snapshotTracker <= snapshotTracker + 1;
                case writeSnapshotJobs(snapshotTracker).previousRinglet is
                    when STATE_Initial =>
                        for s in 0 to 1 loop
                            if initialWriteSnapshots(s).observed = true and initialWriteSnapshots(s).executeOnEntry = writeSnapshotJobs(snapshotTracker).executeOnEntry then
                                skippedJobs := skippedJobs + 729;
                                exit;
                            elsif initialWriteSnapshots(s).observed = false then
                                initialWriteSnapshots(s) <= (
                                    executeOnEntry => writeSnapshotJobs(snapshotTracker).executeOnEntry,
                                    observed => true
                                );
                                for e in 0 to 1 loop
                                    if initialEdges(e).observed = false then
                                        initialEdges(e) <= (
                                            write => (
                                                executeOnEntry => writeSnapshotJobs(snapshotTracker).executeOnEntry,
                                                observed => true
                                            ),
                                            nextState => writeSnapshotJobs(snapshotTracker).currentState,
                                            observed => true
                                        );
                                        exit;
                                    elsif e = 1 and initialEdges(e).observed = true then
                                        hasError := true;
                                    end if;
                                end loop;
                                case writeSnapshotJobs(snapshotTracker).currentState is
                                    when STATE_Initial =>
                                        for s in 0 to 1 loop
                                            if initialReadSnapshots(s).observed = true and initialReadSnapshots(s).executeOnEntry = (writeSnapshotJobs(snapshotTracker).previousRinglet /= writeSnapshotJobs(snapshotTracker).currentState) then
                                                skippedJobs := skippedJobs + 1;
                                                exit;
                                            else
                                                for j in 0 to 1611 loop
                                                    if allJobs(j).observed = true and allJobs(j).executeOnEntry = (writeSnapshotJobs(snapshotTracker).previousRinglet /= writeSnapshotJobs(snapshotTracker).currentState) then
                                                        skippedJobs := skippedJobs + 1;
                                                        exit;
                                                    elsif allJobs(j).observed = false then
                                                        allJobs(j) <= (
                                                            demand => writeSnapshotJobs(snapshotTracker).demand,
                                                            heat => writeSnapshotJobs(snapshotTracker).heat,
                                                            relayOn => writeSnapshotJobs(snapshotTracker).relayOn,
                                                            fr_demand => writeSnapshotJobs(snapshotTracker).demand,
                                                            fr_heat => writeSnapshotJobs(snapshotTracker).heat,
                                                            currentState => writeSnapshotJobs(snapshotTracker).currentState,
                                                            previousRinglet => writeSnapshotJobs(snapshotTracker).previousRinglet,
                                                            internalState => writeSnapshotJobs(snapshotTracker).internalState,
                                                            executeOnEntry => writeSnapshotJobs(snapshotTracker).previousRinglet /= writeSnapshotJobs(snapshotTracker).currentState,
                                                            observed => true
                                                        );
                                                        exit;
                                                    elsif j = 1611 and allJobs(j).observed = true then
                                                        hasError := true;
                                                    end if;
                                                end loop;
                                            end if;
                                        end loop;
                                    when others =>
                                        null;
                                end case;
                                exit;
                            elsif s = 1 and initialWriteSnapshots(s).observed = true then
                                stateTracker <= Error;
                            end if;
                        end loop;
                    when others =>
                        null;
                end case;
            end if;
        when others =>
            null;
    end case;
end if;
end process;


end Behavioral;

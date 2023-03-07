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
            currentStateOut => STATE_Initial,
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
            currentStateOut => STATE_Initial,
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
    constant FilterJobs: std_logic_vector(3 downto 0) := x"9";
    constant FilterWriteSnapshots: std_logic_vector(3 downto 0) := x"A";
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
            FurnaceRelay_currentStateOut => currentJobs(i).currentStateOut,
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
variable initialReadIndex: integer range -1 to 1 := -1;
variable frOffReadIndex: integer range -1 to 1457 := -1;
variable frOnReadIndex: integer range -1 to 161 := -1;
variable initialWriteIndex: integer range -1 to 1 := -1;
variable frOffWriteIndex: integer range -1 to 1457 := -1;
variable frOnWriteIndex: integer range -1 to 161 := -1;
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
                            currentStateOut => STATE_Initial,
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
                    stateTracker <= FilterJobs;
                end if;
            end if;
            lastIndexSaved <= lastIndex;
            skippedJobsSaved <= skippedJobs;
--        when FilterJobs =>
--            for i in 1 to 1611 loop
--                if currentJobs(i).observed then
--                    for c in 0 to i - 1 loop
--                        if currentJobs(c).observed and currentJobs(c).currentState = currentJobs(i).currentState and currentJobs(c).executeOnEntry = currentJobs(i).executeOnEntry then
--                            case currentJobs(i).currentState is
--                                when STATE_Initial =>
--                                    currentJobs(i).observed <= false;
--                                    exit;
--                                when STATE_FROff =>
--                                    if currentJobs(c).demand = currentJobs(i).demand and currentJobs(c).heat = currentJobs(i).heat then
--                                        currentJobs(i).observed <= false;
--                                        exit;
--                                    end if;
--                                when STATE_FROn =>
--                                    if currentJobs(c).demand = currentJobs(i).demand then
--                                        currentJobs(i).observed <= false;
--                                        exit;
--                                    end if;
--                            end case;
--                        end if;
--                    end loop;
--                end if;
--            end loop;
--            stateTracker <= ExecuteReadSnapshot;
--        when ExecuteReadSnapshot =>
--            initialReadIndex := -1;
--            frOffReadIndex := -1;
--            frOnReadIndex := -1;
--            for c in 0 to 1611 loop
--                if currentJobs(c).observed then
--                    case currentJobs(c).currentState is
--                        when STATE_Initial =>
--                            for s in 0 to 1 loop
--                                if initialReadSnapshots(s).observed = false and s > initialReadIndex then
--                                    initialReadSnapshots(s) <= (
--                                        executeOnEntry => currentJobs(c).executeOnEntry,
--                                        observed => true
--                                    );
--                                    initialReadIndex := s;
--                                    exit;
--                                elsif s = 1 and initialReadSnapshots(s).observed = true then
--                                    hasError := true;
--                                end if;
--                            end loop;
--                        when STATE_FROff =>
--                            for s in 0 to 1457 loop
--                                if frOffReadSnapshots(s).observed = false and s > frOffReadIndex then
--                                    frOffReadSnapshots(s) <= (
--                                        demand => currentJobs(c).demand,
--                                        heat => currentJobs(c).heat,
--                                        executeOnEntry => currentJobs(c).executeOnEntry,
--                                        observed => true
--                                    );
--                                    frOffReadIndex := s;
--                                    exit;
--                                elsif s = 1457 and frOffReadSnapshots(s).observed = true then
--                                    hasError := true;
--                                end if;
--                            end loop;
--                        when STATE_FROn =>
--                            for s in 0 to 161 loop
--                                if frOnReadSnapshots(s).observed = false and s > frOnReadIndex then
--                                    frOnReadSnapshots(s) <= (
--                                        demand => currentJobs(c).demand,
--                                        executeOnEntry => currentJobs(c).executeOnEntry,
--                                        observed => true
--                                    );
--                                    frOnReadIndex := s;
--                                    exit;
--                                elsif s = 161 and frOnReadSnapshots(s).observed = true then
--                                    hasError := true;
--                                end if;
--                            end loop;
--                        when others =>
--                            null;
--                    end case;
--                end if;
--            end loop;
--            if hasError then
--                stateTracker <= Error;
--            else
--                for c2 in 0 to 1611 loop
--                    if c2 = 1611 and currentJobs(c2).observed = false then
--                        reset <= '0';
--                        for i in 0 to 1611 loop
--                            currentJobs(i).internalState <= WriteSnapshot;
--                        end loop;
--                        stateTracker <= CalculateEdgeSetup;
--                    els
--                    if currentJobs(c2).observed then
--                        reset <= '1';
--                        stateTracker <= WaitForWriteSnapshot;
--                        exit;
--                    end if;
--                end loop;
--            end if;
--        when WaitForWriteSnapshot =>
--            initialReadIndex := -1;
--            frOffReadIndex := -1;
--            frOnReadIndex := -1;
--            initialWriteIndex := -1;
--            frOffWriteIndex := -1;
--            frOnWriteIndex := -1;
--            if internalState = WriteSnapshot then
--                reset <= '0';
--                skippedWrites := 0;
--                for i in 0 to (lastIndex - skippedJobs) loop
--                    case currentJobs(i).currentState is
--                        when STATE_Initial =>
--                            for r in 0 to 1 loop
--                                if initialRinglets(r).observed = false and r > initialReadIndex then
--                                    initialRinglets(r) <= (
--                                        read => (executeOnEntry => currentJobs(i).executeOnEntry, observed => true),
--                                        write => (executeOnEntry => currentJobs(i).executeOnEntry, observed => true),
--                                        observed => true
--                                    );
--                                    initialReadIndex := r;
--                                    exit;
--                                end if;
--                            end loop;
--                            for w in 0 to 1 loop
--                                if initialWriteSnapshots(w).observed = true and initialWriteSnapshots(w).executeOnEntry = currentJobs(i).executeOnEntry then
--                                    skippedWrites := skippedWrites + 1;
--                                    exit;
--                                elsif initialWriteSnapshots(w).observed = false and w > initialWriteIndex then
--                                    initialWriteSnapshots(w) <= (executeOnEntry => currentJobs(i).executeOnentry, observed => true);
--                                    writeSnapshotJobs(i - skippedWrites) <= currentJobs(i);
--                                    initialWriteIndex := w;
--                                    exit;
--                                elsif w = 1 and initialWriteSnapshots(w).observed = true then
--                                    hasError := true;
--                                end if;
--                            end loop;
--                        when STATE_FROff =>
--                            for r in 0 to 1457 loop
--                                if frOffRinglets(r).observed = false and r > frOffReadIndex then
--                                    frOffRinglets(r) <= (
--                                        read => (
--                                            demand => currentJobs(i).demand,
--                                            heat => currentJobs(i).heat,
--                                            executeOnEntry => currentJobs(i).executeOnEntry,
--                                            observed => true
--                                        ),
--                                        write => (
--                                            demand => currentJobs(i).fr_demand,
--                                            heat => currentJobs(i).fr_heat,
--                                            relayOn => currentJobs(i).relayOn,
--                                            executeOnEntry => currentJobs(i).executeOnEntry,
--                                            observed => true
--                                        ),
--                                        observed => true
--                                    );
--                                    frOffReadIndex := r;
--                                    exit;
--                                end if;
--                            end loop;
--                            for w in 0 to 1457 loop
--                                if frOffWriteSnapshots(w).demand = currentJobs(i).fr_demand and frOffWriteSnapshots(w).heat = currentJobs(i).fr_heat and frOffWriteSnapshots(w).relayOn = currentJobs(i).relayOn and frOffWriteSnapshots(w).executeOnEntry = currentJobs(i).executeOnEntry and frOffWriteSnapshots(w).observed = true then
--                                    skippedWrites := skippedWrites + 1;
--                                    exit;
--                                elsif frOffWriteSnapshots(w).observed = false and w > frOffWriteIndex then
--                                    frOffWriteSnapshots(w) <= (
--                                        demand => currentJobs(i).fr_demand,
--                                        heat => currentJobs(i).fr_heat,
--                                        relayOn => currentJobs(i).relayOn,
--                                        executeOnEntry => currentJobs(i).executeOnEntry,
--                                        observed => true
--                                    );
--                                    writeSnapshotJobs(i - skippedWrites) <= currentJobs(i);
--                                    frOffWriteIndex := w;
--                                    exit;
--                                elsif w = 1457 and frOffWriteSnapshots(w).observed = true then
--                                    hasError := true;
--                                end if;
--                            end loop;
--                        when STATE_FROn =>
--                            for r in 0 to 161 loop
--                                if frOnRinglets(r).observed = false and r > frOnReadIndex then
--                                    frOnRinglets(r) <= (
--                                        read => (
--                                            demand => currentJobs(i).demand,
--                                            executeOnEntry => currentJobs(i).executeOnEntry,
--                                            observed => true
--                                        ),
--                                        write => (
--                                            demand => currentJobs(i).fr_demand,
--                                            relayOn => currentJobs(i).relayOn,
--                                            executeOnEntry => currentJobs(i).executeOnEntry,
--                                            observed => true
--                                        ),
--                                        observed => true
--                                    );
--                                    frOnReadIndex := r;
--                                    exit;
--                                end if;
--                            end loop;
--                            for w in 0 to 161 loop
--                                if frOnWriteSnapshots(w).demand = currentJobs(i).fr_demand and frOnWriteSnapshots(w).relayOn = currentJobs(i).relayOn and frOnWriteSnapshots(w).observed = true and frOnWriteSnapshots(w).executeOnEntry = currentJobs(i).executeOnEntry then
--                                    skippedWrites := skippedWrites + 1;
--                                    exit;
--                                elsif frOnWriteSnapshots(w).observed = false and w > frOnWriteIndex then
--                                    frOnWriteSnapshots(w) <= (demand => currentJobs(i).fr_demand, relayOn => currentJobs(i).relayOn, executeOnEntry => currentJobs(i).executeOnEntry, observed => true);
--                                    writeSnapshotJobs(i - skippedWrites) <= currentJobs(i);
--                                    frOnWriteIndex := w;
--                                    exit;
--                                elsif w = 161 and frOnWriteSnapshots(w).observed = true then
--                                    hasError := true;
--                                end if;
--                            end loop;
--                        when others =>
--                            null;
--                    end case;
--                end loop;
--                if hasError then
--                    stateTracker <= Error;
--                else
--                    stateTracker <= FilterWriteSnapshots;
--                end if;
--            end if;
        when FilterWriteSnapshots =>
            for i in 1 to 1611 loop
                if writeSnapshotJobs(i).observed then
                    for j in 0 to i - 1 loop
                        if writeSnapshotJobs(j).observed then
                            case writeSnapshotJobs(i).currentState is
                                when STATE_Initial =>
                                    if writeSnapshotJobs(j).executeOnEntry = writeSnapshotJobs(i).executeOnEntry then
                                        writeSnapshotJobs(i).observed <= false;
                                        exit;
                                    end if;
                                when STATE_FROff =>
                                    if writeSnapshotJobs(j).demand = writeSnapshotJobs(i).demand and writeSnapshotJobs(j).heat = writeSnapshotJobs(i).heat and writeSnapshotJobs(i).executeOnEntry = writeSnapshotJobs(j).executeOnEntry and writeSnapshotJobs(j).relayOn = writeSnapshotJobs(i).relayOn then
                                        writeSnapshotJobs(i).observed <= false;
                                        exit;
                                    end if;
                                when STATE_FROn =>
                                    if writeSnapshotJobs(j).demand = writeSnapshotJobs(i).demand and writeSnapshotJobs(i).executeOnEntry = writeSnapshotJobs(j).executeOnEntry and writeSnapshotJobs(j).relayOn = writeSnapshotJobs(i).relayOn then
                                        writeSnapshotJobs(i).observed <= false;
                                        exit;
                                    end if;
                            end case;
                        end if;
                    end loop;
                end if;
            end loop;
            stateTracker <= CalculateEdgeSetup;
        when CalculateEdgeSetup =>
            for k in 0 to 1611 loop
                if writeSnapshotJobs(k).observed then
                    snapshotTracker <= k;
                    stateTracker <= SetWriteSnapshotJobs;
                    skippedJobs := 0;
                    exit;
                elsif k = 1611 then
                    stateTracker <= GenerateWorkingJob;
                end if;
            end loop;
--        when SetWriteSnapshotJobs =>
--            case writeSnapshotJobs(snapshotTracker).currentState is
--                when STATE_Initial =>
--                    for s in 0 to 1 loop
--                        if initialWriteSnapshots(s).observed = true and initialWriteSnapshots(s).executeOnEntry = writeSnapshotJobs(snapshotTracker).executeOnEntry then
--                            skippedJobs := skippedJobs + 729;
--                            exit;
--                        elsif initialWriteSnapshots(s).observed = false then
--                            initialWriteSnapshots(s) <= (
--                                executeOnEntry => writeSnapshotJobs(snapshotTracker).executeOnEntry,
--                                observed => true
--                            );
--                            for e in 0 to 1 loop
--                                if initialEdges(e).observed = false then
--                                    initialEdges(e) <= (
--                                        write => (
--                                            executeOnEntry => writeSnapshotJobs(snapshotTracker).executeOnEntry,
--                                            observed => true
--                                        ),
--                                        nextState => writeSnapshotJobs(snapshotTracker).currentStateOut,
--                                        observed => true
--                                    );
--                                    exit;
--                                elsif e = 1 and initialEdges(e).observed = true then
--                                    hasError := true;
--                                end if;
--                            end loop;
--                            case writeSnapshotJobs(snapshotTracker).currentStateOut is
--                                when STATE_Initial =>
--                                    for s in 0 to 1 loop
--                                        if initialReadSnapshots(s).observed = true and initialReadSnapshots(s).executeOnEntry = (writeSnapshotJobs(snapshotTracker).currentState /= writeSnapshotJobs(snapshotTracker).currentStateOut) then
--                                            skippedJobs := skippedJobs + 1;
--                                            exit;
--                                        elsif initialReadSnapshots(s).observed = false then
--                                            for j in 0 to 1611 loop
--                                                if allJobs(j).observed = true and allJobs(j).executeOnEntry = (writeSnapshotJobs(snapshotTracker).currentState /= writeSnapshotJobs(snapshotTracker).currentStateOut) then
--                                                    skippedJobs := skippedJobs + 1;
--                                                    exit;
--                                                elsif allJobs(j).observed = false then
--                                                    allJobs(j) <= (
--                                                        demand => writeSnapshotJobs(snapshotTracker).fr_demand,
--                                                        heat => writeSnapshotJobs(snapshotTracker).fr_heat,
--                                                        relayOn => writeSnapshotJobs(snapshotTracker).relayOn,
--                                                        fr_demand => writeSnapshotJobs(snapshotTracker).fr_demand,
--                                                        fr_heat => writeSnapshotJobs(snapshotTracker).fr_heat,
--                                                        currentState => writeSnapshotJobs(snapshotTracker).currentStateOut,
--                                                        previousRinglet => writeSnapshotJobs(snapshotTracker).currentState,
--                                                        internalState => writeSnapshotJobs(snapshotTracker).internalState,
--                                                        currentStateOut => writeSnapshotJobs(snapshotTracker).currentStateOut,
--                                                        executeOnEntry => writeSnapshotJobs(snapshotTracker).currentState /= writeSnapshotJobs(snapshotTracker).currentStateOut,
--                                                        observed => true
--                                                    );
--                                                    exit;
--                                                elsif j = 1611 and allJobs(j).observed = true then
--                                                    hasError := true;
--                                                end if;
--                                            end loop;
--                                        elsif initialReadSnapshots(s).observed = true and s = 1 then
--                                            hasError := true;
--                                        end if;
--                                    end loop;
--                                when STATE_FROff =>
--                                    for i0 in 0 to 8 loop
--                                        for i1 in 0 to 8 loop
--                                            for i2 in 0 to 8 loop
--                                                for s in 0 to 1457 loop
--                                                    if frOffReadSnapshots(s).observed and frOffReadSnapshots(s).demand = (stdLogicTypes(i0) & stdLogicTypes(i1)) and frOffReadSnapshots(s).heat = stdLogicTypes(i2) and frOffReadSnapshots(s).executeOnEntry = (writeSnapshotJobs(snapshotTracker).currentState /= writeSnapshotJobs(snapshotTracker).currentStateOut) then
--                                                        exit;
--                                                    elsif frOffReadSnapshots(s).observed = false then
--                                                        for jobIndex in 0 to 1611 loop
--                                                            if allJobs(jobIndex).observed = false then
--                                                                allJobs(jobIndex) <= (
--                                                                    demand => (stdLogicTypes(i0) & stdLogicTypes(i1)),
--                                                                    heat => stdLogicTypes(i2),
--                                                                    relayOn => writeSnapshotJobs(snapshotTracker).relayOn,
--                                                                    fr_demand => writeSnapshotJobs(snapshotTracker).fr_demand,
--                                                                    fr_heat => writeSnapshotJobs(snapshotTracker).fr_heat,
--                                                                    currentState => writeSnapshotJobs(snapshotTracker).currentStateOut,
--                                                                    previousRinglet => writeSnapshotJobs(snapshotTracker).currentState,
--                                                                    internalState => writeSnapshotJobs(snapshotTracker).internalState,
--                                                                    currentStateOut => writeSnapshotJobs(snapshotTracker).currentStateOut,
--                                                                    executeOnEntry => writeSnapshotJobs(snapshotTracker).currentState /= writeSnapshotJobs(snapshotTracker).currentStateOut,
--                                                                    observed => true
--                                                                );
--                                                            elsif allJobs(jobIndex).observed and jobIndex = 1611 then
--                                                                hasError := true;
--                                                            end if;
--                                                        end loop;
--                                                    elsif frOffReadSnapshots(s).observed = true and s = 1457 then
--                                                        hasError := true;
--                                                    end if;
--                                                end loop;
--                                            end loop;
--                                        end loop;
--                                    end loop;
--                                when others =>
--                                    null;
--                            end case;
--                            exit;
--                        elsif s = 1 and initialWriteSnapshots(s).observed = true then
--                            stateTracker <= Error;
--                        end if;
--                    end loop;
--                when others =>
--                    null;
--            end case;
--            if hasError then
--                stateTracker <= Error;
--            elsif snapshotTracker = 1611 then
--                snapshotTracker <= 0;
--                stateTracker <= GenerateWorkingJob;
--            else
--                for t in snapshotTracker + 1 to 1611 loop
--                    if writeSnapshotJobs(t).observed then
--                        snapshotTracker <= t;
--                        exit;
--                    elsif t = 1611 then
--                        snapshotTracker <= 0;
--                        stateTracker <= GenerateWorkingJob;
--                    end if;
--                end loop;
--            end if;
        when others =>
            null;
    end case;
end if;
end process;


end Behavioral;

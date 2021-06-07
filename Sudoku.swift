import Foundation

class Sudoku {
    
    private var solvedTable: [[Int]]?
    private func correctPlacementSolve( _ table: [[Int]], _ allUnfilledPoints: [(Int,Int)], _ unfilledMissingSets: [Int:Set<Int>]) {
        var table = table
        var allUnfilledPoints = allUnfilledPoints
        var unfilledMissingSets = unfilledMissingSets
        var stack: [(Int,Int)] = []
        // Try and fill all unfilled cells with their definite value, end if already solved or gone through all cells
        while !allUnfilledPoints.isEmpty {
            guard solvedTable == nil else { return }
            if fillPoint(&table, allUnfilledPoints.removeLast(), &stack, &unfilledMissingSets) { return }
        }
        // Conduct box/line/naked/hidden reductions
        boxReduction(&unfilledMissingSets)
        rowColReduction(&unfilledMissingSets)
        nakedTriplesReduction(&unfilledMissingSets)
        nakedPairsReduction(&unfilledMissingSets)
        hiddenPairsReduction(&unfilledMissingSets)
        // Try and solve the unfilled neighbour cells of recently filled cells
        if !unfilledMissingSets.isEmpty {
            while !stack.isEmpty {
                guard solvedTable == nil else { return }
                if fillNeighbours(&stack, stack.removeLast(), &table, &unfilledMissingSets) { return }
            }
        }
        // If some cells are still unsolved, make guess a cell and continue solution in a new queue, else print solution
        if !unfilledMissingSets.isEmpty {
            // Get the unfilled cell with the minimum missing values, use it to branch
            var minMissingItem: Int = unfilledMissingSets.keys.first!
            var missing: Set<Int> = unfilledMissingSets[minMissingItem]!
            for (i,v) in unfilledMissingSets {
                if v.count < missing.count {
                    minMissingItem = i
                    missing = v
                }
            }
            unfilledMissingSets[minMissingItem] = nil
            let row = minMissingItem / 10
            let col = minMissingItem % 10
            for (i,_) in unfilledMissingSets {
                allUnfilledPoints.append((i/10,i%10))
            }
            while !missing.isEmpty {
                table[row][col] = missing.removeFirst()
                let newTable = table
                let newAllUnfilledPoints = allUnfilledPoints
                var newUnfilledMissingSets = unfilledMissingSets
                updateUnfilledMissingSets(table[row][col], (row,col), &newUnfilledMissingSets)
                DispatchQueue.global().async {
                    self.correctPlacementSolve(newTable, newAllUnfilledPoints, newUnfilledMissingSets)
                }
            }
        } else {
            self.solvedTable = table
            printTable(table)
        }
    }
    // O(n * m) - Where n is the number of rows and m is the number of possible values. Optimized by reducing m
    private func hiddenPairsReduction(_ unfilledMissingSets: inout [Int:Set<Int>]) {
        // Iterate through each row
        for i in 0..<9 {
            // Record the cells each value occurs in
            var setContaining: [Int:Set<Int>] = [1:[],2:[],3:[],4:[],5:[],6:[],7:[],8:[],9:[]]
            for j in 0..<9 {
                if let set = unfilledMissingSets[i * 10 + j] {
                    for s in set {
                        setContaining[s]!.insert(i * 10 + j)
                    }
                }
            }
            // Store the values that appear in exactly 2 cells
            for (i,v) in setContaining {
                if v.count != 2 { setContaining[i] = nil }
            }
            // Find two values that occur in the same set of cells
            for (i,v) in setContaining {
                for (j,w) in setContaining {
                    if i != j && v == w {
                        for s in v {
                            unfilledMissingSets[s] = [i,j]
                        }
                        setContaining[j] = nil
                        break
                    }
                }
            }
        }
        // Iterate through each column
        for i in 0..<9 {
            // Record the cells each value occurs in
            var setContaining: [Int:Set<Int>] = [1:[],2:[],3:[],4:[],5:[],6:[],7:[],8:[],9:[]]
            for j in 0..<9 {
                if let set = unfilledMissingSets[j * 10 + i] {
                    for s in set {
                        setContaining[s]!.insert(j * 10 + i)
                    }
                }
            }
            // Store the values that appear in exactly 2 cells
            for (i,v) in setContaining {
                if v.count != 2 { setContaining[i] = nil }
            }
            // Find two values that occur in the same set of cells
            for (i,v) in setContaining {
                for (j,w) in setContaining {
                    if i != j && v == w {
                        for s in v {
                            unfilledMissingSets[s] = [i,j]
                        }
                        setContaining[j] = nil
                        break
                    }
                }
            }
        }
        // Iterate through each box
        for i in 0..<9 {
            let minRowBck = (i / 3) * 3
            let minColBck = (i % 3) * 3
            // Record the cells each value occurs in
            var setContaining: [Int:Set<Int>] = [1:[],2:[],3:[],4:[],5:[],6:[],7:[],8:[],9:[]]
            for i in minRowBck..<(minRowBck + 3) {
                for j in minColBck..<(minColBck + 3) {
                    if let set = unfilledMissingSets[i * 10 + j] {
                        for s in set {
                            setContaining[s]!.insert(i * 10 + j)
                        }
                    }
                }
            }
            // Store the values that appear in exactly 2 cells
            for (i,v) in setContaining {
                if v.count != 2 { setContaining[i] = nil }
            }
            // Find two values that occur in the same set of cells
            for (i,v) in setContaining {
                for (j,w) in setContaining {
                    if i != j && v == w {
                        for s in v {
                            unfilledMissingSets[s] = [i,j]
                        }
                        setContaining[j] = nil
                        break
                    }
                }
            }
        }
        
    }
    // O(p * n) - Where p is the size of unfilled missing cells, and n is the number of cells in a row/col/box. Optimized by reducing p.
    private func nakedPairsReduction(_ unfilledMissingSets: inout [Int:Set<Int>]) {
        // Iterate through all the unfilled cells testing for cells with exactly 2 possible values
        loop1: for (i,v) in unfilledMissingSets {
            if v.count == 2 {
                let row = i / 10
                let col = i % 10
                // Iterate through the cells row to find a twin cell with the same exact possible values i.e a naked pair
                for i in 0..<col {
                    if let cell = unfilledMissingSets[row * 10 + i] {
                        if cell == v {
                            // Because a naked pair was found, remove all possible values in the pair from all other cells in the row
                            for k in 0..<i {
                                for l in v {
                                    unfilledMissingSets[row * 10 + k]?.remove(l)
                                }
                            }
                            for k in (i+1)..<col {
                                for l in v {
                                    unfilledMissingSets[row * 10 + k]?.remove(l)
                                }
                            }
                            for k in (col+1)..<9 {
                                for l in v {
                                    unfilledMissingSets[row * 10 + k]?.remove(l)
                                }
                            }
                            continue loop1
                        }
                    }
                }
                for i in (col + 1)..<9 {
                    if let cell = unfilledMissingSets[row * 10 + i] {
                        if cell == v  {
                            for k in 0..<col {
                                for l in v {
                                    unfilledMissingSets[row * 10 + k]?.remove(l)
                                }
                            }
                            for k in (col+1)..<i {
                                for l in v {
                                    unfilledMissingSets[row * 10 + k]?.remove(l)
                                }
                            }
                            for k in (i+1)..<9 {
                                for l in v {
                                    unfilledMissingSets[row * 10 + k]?.remove(l)
                                }
                            }
                            continue loop1
                        }
                    }
                }
            }
        }
        // Iterate through all the unfilled cells testing for cells with exactly 2 possible values
        loop2: for (i,v) in unfilledMissingSets {
            if v.count == 2 {
                let row = i / 10
                let col = i % 10
                // Iterate through the cells column to find a twin cell with the same exact possible values i.e a naked pair
                for i in 0..<row {
                    if let cell = unfilledMissingSets[i * 10 + col] {
                        if cell == v {
                            // Because a naked pair was found, remove all possible values in the pair from all other cells in the column
                            for k in 0..<i {
                                for l in v {
                                    unfilledMissingSets[k * 10 + col]?.remove(l)
                                }
                            }
                            for k in (i+1)..<row {
                                for l in v {
                                    unfilledMissingSets[k * 10 + col]?.remove(l)
                                }
                            }
                            for k in (row+1)..<9 {
                                for l in v {
                                    unfilledMissingSets[k * 10 + col]?.remove(l)
                                }
                            }
                            continue loop2
                        }
                    }
                }
                for i in (row + 1)..<9 {
                    if let cell = unfilledMissingSets[i * 10 + col] {
                        if cell == v {
                            for k in 0..<row {
                                for l in v {
                                    unfilledMissingSets[k * 10 + col]?.remove(l)
                                }
                            }
                            for k in (row+1)..<i {
                                for l in v {
                                    unfilledMissingSets[k * 10 + col]?.remove(l)
                                }
                            }
                            for k in (i+1)..<9 {
                                for l in v {
                                    unfilledMissingSets[k * 10 + col]?.remove(l)
                                }
                            }
                            continue loop2
                        }
                    }
                }
            }
        }
        // Iterate through all the unfilled cells testing for cells with exactly 2 possible values
        loop3: for (i,v) in unfilledMissingSets {
            if v.count == 2 {
                let row = i / 10
                let col = i % 10
                // Iterate through the cells box to find a twin cell with the same exact possible values i.e a naked pair
                let minRowBck = (row / 3) * 3
                let minColBck = (col / 3) * 3
                for i in minRowBck..<(minRowBck + 3) {
                    for j in minColBck..<(minColBck + 3) {
                        if i == row && j == col { continue }
                        if let cell = unfilledMissingSets[i * 10 + j] {
                            if cell == v {
                                // Because a naked pair was found, remove all possible values in the pair from all other cells in the box
                                for k in minRowBck..<(minRowBck + 3) {
                                    for l in minColBck..<(minColBck + 3) {
                                        if k == row && l == col || k ==  i && l == j { continue }
                                        for xyz in v {
                                            unfilledMissingSets[k * 10 + l]?.remove(xyz)
                                        }
                                    }
                                }
                                continue loop3
                            }
                        }
                    }
                }

            }
        }
    }
    // O(p * n) - Where p is the size of unfilled missing cells, and n is the number of cells in a row/col/box. Optimized by reducing p.
    private func nakedTriplesReduction(_ unfilledMissingSets: inout [Int:Set<Int>]) {
        // Iterate through all the unfilled cells testing for cells with exactly 3 possible values...there must be at least one
        loop1: for (i,v) in unfilledMissingSets {
            if v.count == 3 {
                let row = i / 10
                let col = i % 10
                // Iterate through the cells entire row and find 2 other cells that contain only numbers in v i.e naked triple
                var firstIndex = -1
                for i in 0..<col {
                    if let cell = unfilledMissingSets[row * 10 + i] {
                        if v.isSuperset(of: cell) {
                            if firstIndex > 0 {
                                // Remove all numbers in v from the rest of the row's cells
                                for k in 0..<firstIndex {
                                    for l in v {
                                        unfilledMissingSets[row * 10 + k]?.remove(l)
                                    }
                                }
                                for k in (firstIndex + 1)..<i {
                                    for l in v {
                                        unfilledMissingSets[row * 10 + k]?.remove(l)
                                    }
                                }
                                for k in (i+1)..<col {
                                    for l in v {
                                        unfilledMissingSets[row * 10 + k]?.remove(l)
                                    }
                                }
                                for k in (col+1)..<9 {
                                    for l in v {
                                        unfilledMissingSets[row * 10 + k]?.remove(l)
                                    }
                                }
                                continue loop1
                            } else {
                                firstIndex = i
                            }
                        }
                    }
                }
                if firstIndex > 0 {
                    for i in (col + 1)..<9 {
                        if let cell = unfilledMissingSets[row * 10 + i] {
                            if v.isSuperset(of: cell) {
                                if firstIndex > 0 {
                                    for k in 0..<firstIndex {
                                        for l in v {
                                            unfilledMissingSets[row * 10 + k]?.remove(l)
                                        }
                                    }
                                    for k in (firstIndex+1)..<col {
                                        for l in v {
                                            unfilledMissingSets[row * 10 + k]?.remove(l)
                                        }
                                    }
                                    for k in (col+1)..<i {
                                        for l in v {
                                            unfilledMissingSets[row * 10 + k]?.remove(l)
                                        }
                                    }
                                    for k in (i+1)..<9 {
                                        for l in v {
                                            unfilledMissingSets[row * 10 + k]?.remove(l)
                                        }
                                    }
                                    continue loop1
                                } else {
                                    firstIndex = i
                                }
                            }
                        }
                    }
                } else {
                    for i in (col + 1)..<9 {
                        if let cell = unfilledMissingSets[row * 10 + i] {
                            if v.isSuperset(of: cell) {
                                if firstIndex > 0 {
                                    for k in 0..<col {
                                        for l in v {
                                            unfilledMissingSets[row * 10 + k]?.remove(l)
                                        }
                                    }
                                    for k in (col+1)..<firstIndex {
                                        for l in v {
                                            unfilledMissingSets[row * 10 + k]?.remove(l)
                                        }
                                    }
                                    for k in (firstIndex+1)..<i {
                                        for l in v {
                                            unfilledMissingSets[row * 10 + k]?.remove(l)
                                        }
                                    }
                                    for k in (i+1)..<9 {
                                        for l in v {
                                            unfilledMissingSets[row * 10 + k]?.remove(l)
                                        }
                                    }
                                    continue loop1
                                } else {
                                    firstIndex = i
                                }
                            }
                        }
                    }
                }
            }
        }
        // Iterate through all the unfilled cells testing for cells with exactly 3 possible values...there must be at least one
        loop2: for (i,v) in unfilledMissingSets {
            if v.count == 3 {
                let row = i / 10
                let col = i % 10
                // Iterate through the cells entire row and find 2 other cells that contain only numbers in v i.e naked triple
                var firstIndex = -1
                for i in 0..<row {
                    if let cell = unfilledMissingSets[i * 10 + col] {
                        if v.isSuperset(of: cell) {
                            // Remove all numbers in v from the rest of the row's cells
                            if firstIndex > 0 {
                                for k in 0..<firstIndex {
                                    for l in v {
                                        unfilledMissingSets[k * 10 + col]?.remove(l)
                                    }
                                }
                                for k in (firstIndex+1)..<i {
                                    for l in v {
                                        unfilledMissingSets[k * 10 + col]?.remove(l)
                                    }
                                }
                                for k in (i+1)..<row {
                                    for l in v {
                                        unfilledMissingSets[k * 10 + col]?.remove(l)
                                    }
                                }
                                for k in (row+1)..<9 {
                                    for l in v {
                                        unfilledMissingSets[k * 10 + col]?.remove(l)
                                    }
                                }
                                continue loop2
                            } else {
                                firstIndex = i
                            }
                        }
                    }
                }
                if firstIndex > 0 {
                    for i in (row + 1)..<9 {
                        if let cell = unfilledMissingSets[i * 10 + col] {
                            if v.isSuperset(of: cell) {
                                if firstIndex > 0 {
                                    for k in 0..<firstIndex {
                                        for l in v {
                                            unfilledMissingSets[k * 10 + col]?.remove(l)
                                        }
                                    }
                                    for k in (firstIndex+1)..<row {
                                        for l in v {
                                            unfilledMissingSets[k * 10 + col]?.remove(l)
                                        }
                                    }
                                    for k in (row+1)..<i {
                                        for l in v {
                                            unfilledMissingSets[k * 10 + col]?.remove(l)
                                        }
                                    }
                                    for k in (i+1)..<9 {
                                        for l in v {
                                            unfilledMissingSets[k * 10 + col]?.remove(l)
                                        }
                                    }
                                    continue loop2
                                } else {
                                    firstIndex = i
                                }
                            }
                        }
                    }
                } else {
                    for i in (row + 1)..<9 {
                        if let cell = unfilledMissingSets[i * 10 + col] {
                            if v.isSuperset(of: cell) {
                                if firstIndex > 0 {
                                    for k in 0..<row {
                                        for l in v {
                                            unfilledMissingSets[k * 10 + col]?.remove(l)
                                        }
                                    }
                                    for k in (row+1)..<firstIndex {
                                        for l in v {
                                            unfilledMissingSets[k * 10 + col]?.remove(l)
                                        }
                                    }
                                    for k in (firstIndex+1)..<i {
                                        for l in v {
                                            unfilledMissingSets[k * 10 + col]?.remove(l)
                                        }
                                    }
                                    for k in (i+1)..<9 {
                                        for l in v {
                                            unfilledMissingSets[k * 10 + col]?.remove(l)
                                        }
                                    }
                                    continue loop2
                                } else {
                                    firstIndex = i
                                }
                            }
                        }
                    }
                }
            }
        }
        // Iterate through all the unfilled cells testing for cells with exactly 3 possible values...there must be at least one
        loop3: for (i,v) in unfilledMissingSets {
            if v.count == 3 {
                let row = i / 10
                let col = i % 10
                // Iterate through the cells entire row and find 2 other cells that contain only numbers in v i.e naked triple
                var firstIndex = -1
                var secondIndex = -1
                let minRowBck = (row / 3) * 3
                let minColBck = (col / 3) * 3
                for i in minRowBck..<(minRowBck + 3) {
                    for j in minColBck..<(minColBck + 3) {
                        if i == row && j == col { continue }
                        if let cell = unfilledMissingSets[i * 10 + j] {
                            if v.isSuperset(of: cell) {
                                // Remove all numbers in v from the rest of the row's cells
                                if firstIndex > 0 {
                                    for k in minRowBck..<(minRowBck + 3) {
                                        for l in minColBck..<(minColBck + 3) {
                                            if k == row && l == col || k ==  i && l == j || k == firstIndex && l == secondIndex { continue }
                                            for xyz in v {
                                                unfilledMissingSets[k * 10 + l]?.remove(xyz)
                                            }
                                        }
                                    }
                                    continue loop3
                                } else {
                                    firstIndex = i
                                    secondIndex = j
                                }
                            }
                        }
                    }
                }
                
            }
        }
        
    }
    // O(n^1.5 * m) - Where n is the number of rows and m is the number of possible values. Optimized by reducing m
    private func boxReduction(_ unfilledMissingSets: inout [Int:Set<Int>]) {
        // Iterate through all rows
        for i in 0..<9 {
            var missing: Set<Int> = []
            for a in 0..<3 {
                // Batch into 3's. Get all possible values in row within the same box
                missing = []
                let b = 3 * a
                let c = 3 * a + 3
                for j in b..<c {
                    missing = missing.union(unfilledMissingSets[i * 10 + j] ?? [])
                }
                loop: for m in missing {
                    var contains = true
                    for k in 0..<b {
                        if let c = unfilledMissingSets[i * 10 + k]?.contains(m) {
                            if c { continue loop } else { contains = false }
                        }
                    }
                    for k in c..<9 {
                        if let c = unfilledMissingSets[i * 10 + k]?.contains(m) {
                            if c { continue loop } else { contains = false }
                        }
                    }
                    // If they don't exist in the rest of the row, remove them from the rest of the box.
                    if !contains {
                        let minRowBck = (i / 3) * 3
                        for x in minRowBck..<i {
                            for y in b..<c {
                                unfilledMissingSets[x * 10 + y]?.remove(m)
                            }
                        }
                        for x in (i+1)..<(minRowBck + 3) {
                            for y in b..<c {
                                unfilledMissingSets[x * 10 + y]?.remove(m)
                            }
                        }
                    }
                }
            }
            
        }
        // Iterate through all columns
        for i in 0..<9 {
            var missing: Set<Int> = []
            for a in 0..<3 {
                // Batch into 3's. Get all possible values in column within the same box
                missing = []
                let b = 3 * a
                let c = 3 * a + 3
                for j in b..<c {
                    missing = missing.union(unfilledMissingSets[j * 10 + i] ?? [])
                }
                loop: for m in missing {
                    var contains = true
                    for k in 0..<b {
                        if let c = unfilledMissingSets[k * 10 + i]?.contains(m) {
                            if c { continue loop } else { contains = false }
                        }
                    }
                    for k in c..<9 {
                        if let c = unfilledMissingSets[k * 10 + i]?.contains(m) {
                            if c { continue loop } else { contains = false }
                        }
                    }
                    // If they don't exist in the rest of the column, remove them from the rest of the box.
                    if !contains {
                        let minRowBck = (i / 3) * 3
                        for x in minRowBck..<i {
                            for y in b..<c {
                                unfilledMissingSets[y * 10 + x]?.remove(m)
                            }
                        }
                        for x in (i+1)..<(minRowBck + 3) {
                            for y in b..<c {
                                unfilledMissingSets[y * 10 + x]?.remove(m)
                            }
                        }
                    }
                }
            }
        }
        
    }
    // O(n^3) - Where n is the number of rows/cols.
    private func rowColReduction(_ unfilledMissingSets: inout [Int:Set<Int>]) {
        // Iterate through all the boxes
        for i in 0..<9 {
            let minRowBck = (i / 3) * 3
            let minColBck = (i % 3) * 3
            // For each possible value, record the cells that have them only if in the same row
            var row: [Int:[Int]] = [1:[],2:[],3:[],4:[],5:[],6:[],7:[],8:[],9:[]]
            for i in minRowBck..<(minRowBck + 3) {
                for j in minColBck..<(minColBck + 3) {
                    if let set = unfilledMissingSets[i * 10 + j] {
                        for s in set {
                            if let r = row[s] {
                                if r.isEmpty || r.last! / 10 == i {
                                    row[s]!.append(i * 10 + j)
                                } else {
                                    row[s] = nil
                                }
                            }
                        }
                    }
                }
            }
            // Iterate through values of "row", for each possible value remove from other cells in the row not in "row"
            for (i,v) in row {
                if v.isEmpty { continue }
                for l in 0..<9 {
                    if !v.contains((v.last! / 10) * 10 + l) {
                        unfilledMissingSets[(v.last! / 10) * 10 + l]?.remove(i)
                    }
                }
            }
            // For each possible value, record the cells that have them only if in the same column
            var col: [Int:[Int]] = [1:[],2:[],3:[],4:[],5:[],6:[],7:[],8:[],9:[]]
            for i in minRowBck..<(minRowBck + 3) {
                for j in minColBck..<(minColBck + 3) {
                    if let set = unfilledMissingSets[i * 10 + j] {
                        for s in set {
                            if let c = col[s] {
                                if c.isEmpty || c.last! % 10 == j {
                                    col[s]!.append(i * 10 + j)
                                } else {
                                    col[s] = nil
                                }
                            }
                        }
                    }
                }
            }
            // Iterate through values of "col", for each possible value remove from other cells in the row not in "col"
            for (i,v) in col {
                if v.isEmpty { continue }
                for l in 0..<9 {
                    if !v.contains(l * 10 + v.last! % 10) {
                        unfilledMissingSets[l * 10 + v.last! % 10]?.remove(i)
                    }
                }
            }
        }
    }
    // O(n * m) - Fills a cell with a value if possible
    private func fillPoint(_ table: inout [[Int]], _ loc: (Int,Int), _ stack: inout [(Int,Int)], _ unfilledMissingSets: inout [Int:Set<Int>]) -> Bool {
        // Get missing values for the point
        let missing = unfilledMissingSets[loc.0 * 10 + loc.1]!
        // Func needs to end (i.e table is invalid if there are no missing numbers)
        if missing.isEmpty { return true }
        
        if missing.count == 1 {
            return addValueToCell(missing.first!, &table, loc, &stack, &unfilledMissingSets)
        }
        return smartSolve(&table, loc, &stack, &unfilledMissingSets)
    }
    // O(n * m) - Gets possible values from the cell. Checks if there is a possible value unique to the cell within its row/col/box. Then assigns as definite value
    private func smartSolve(_ table: inout [[Int]], _ loc: (Int,Int), _ stack: inout [(Int,Int)], _ unfilledMissingSets: inout [Int:Set<Int>]) -> Bool {
        
        let row = loc.0
        let col = loc.1
        
        let missing = unfilledMissingSets[row * 10 + col]!
        
        loop1: for m in missing { // ROW
            for i in 0..<col {
                if let cell = unfilledMissingSets[row * 10 + i] {
                    if cell.contains(m) {
                        continue loop1
                    }
                }
            }
            for i in (col + 1)..<9 {
                if let cell = unfilledMissingSets[row * 10 + i] {
                    if cell.contains(m) {
                        continue loop1
                    }
                }
            }
            return addValueToCell(m, &table, loc, &stack, &unfilledMissingSets)
        }
        
        loop2: for m in missing { // COL
            for i in 0..<row {
                if let cell = unfilledMissingSets[i * 10 + col] {
                    if cell.contains(m) {
                        continue loop2
                    }
                }
            }
            for i in (row + 1)..<9 {
                if let cell = unfilledMissingSets[i * 10 + col] {
                    if cell.contains(m) {
                        continue loop2
                    }
                }
            }
            return addValueToCell(m, &table, loc, &stack, &unfilledMissingSets)
        }
        
        loop3: for m in missing { // BOX
            let minRowBck = (row / 3) * 3
            let minColBck = (col / 3) * 3
            for i in minRowBck..<(minRowBck + 3) {
                for j in minColBck..<(minColBck + 3) {
                    if i == row && j == col { continue }
                    if let cell = unfilledMissingSets[i * 10 + j] {
                        if cell.contains(m) {
                            continue loop3
                        }
                    }
                }
            }
            return addValueToCell(m, &table, loc, &stack, &unfilledMissingSets)
        }
        
        return false
    }
    // O(q) - Adds a definite value to a cell and its neighbours possible values
    private func addValueToCell(_ value: Int, _ table: inout [[Int]], _ loc: (Int,Int), _ stack: inout [(Int,Int)], _ unfilledMissingSets: inout [Int:Set<Int>]) -> Bool {
        
        let row = loc.0
        let col = loc.1
        
        table[row][col] = value
        stack.append((row,col))
        updateUnfilledMissingSets(table[row][col], loc, &unfilledMissingSets) // O(q)
        
        return false // Function does not need to end (i.e table is still valid)
    }
    // O(q) - Removes the given's cell definite value from it's neighbours possible values
    private func updateUnfilledMissingSets( _ toRemove: Int, _ loc: (Int,Int), _ unfilledMissingSets: inout [Int:Set<Int>]) {
        
        let row = loc.0
        let col = loc.1
        
        unfilledMissingSets[row * 10 + col] = nil
        
        for i in 0..<col {
            unfilledMissingSets[row * 10 + i]?.remove(toRemove)
        }
        for i in (col + 1)..<9 {
            unfilledMissingSets[row * 10 + i]?.remove(toRemove)
        }
        
        for i in 0..<row {
            unfilledMissingSets[i * 10 + col]?.remove(toRemove)
        }
        for i in (row + 1)..<9 {
            unfilledMissingSets[i * 10 + col]?.remove(toRemove)
        }
        
        let minRowBck = (row / 3) * 3
        let minColBck = (col / 3) * 3
        for m in minRowBck..<row {
            for n in minColBck..<col {
                unfilledMissingSets[m * 10 + n]?.remove(toRemove)
            }
            for n in (col + 1)..<(minColBck + 3) {
                unfilledMissingSets[m * 10 + n]?.remove(toRemove)
            }
        }
        for m in (row + 1)..<(minRowBck + 3) {
            for n in minColBck..<col {
                unfilledMissingSets[m * 10 + n]?.remove(toRemove)
            }
            for n in (col + 1)..<(minColBck + 3) {
                unfilledMissingSets[m * 10 + n]?.remove(toRemove)
            }
        }
    }
    // O(q * n * m) - Check the cells neighbours to see if any can be filled
    private func fillNeighbours( _ stack: inout [(Int,Int)], _ loc: (Int,Int), _ table: inout [[Int]], _ unfilledMissingSets: inout [Int:Set<Int>]) -> Bool {
        let row = loc.0
        let col = loc.1
        
        for i in 0..<col {
            if table[row][i] == 0 {
                if fillPoint(&table, (row,i), &stack, &unfilledMissingSets) { return true }
            }
        }
        for i in (col + 1)..<9 {
            if table[row][i] == 0 {
                if fillPoint(&table, (row,i), &stack, &unfilledMissingSets) { return true }
            }
        }
        
        for i in 0..<row {
            if table[i][col] == 0 {
                if fillPoint(&table, (i,col), &stack, &unfilledMissingSets) { return true }
            }
        }
        for i in (row + 1)..<9 {
            if table[i][col] == 0 {
                if fillPoint(&table, (i,col), &stack, &unfilledMissingSets) { return true }
            }
        }
        
        let minRowBck = (row / 3) * 3
        let minColBck = (col / 3) * 3
        
        for m in minRowBck..<row {
            for n in minColBck..<col {
                if table[m][n] == 0 {
                    if fillPoint(&table, (m,n), &stack, &unfilledMissingSets) { return true }
                }
            }
            for n in (col + 1)..<(minColBck + 3) {
                if table[m][n] == 0 {
                    if fillPoint(&table, (m,n), &stack, &unfilledMissingSets) { return true }
                }
            }
        }
        for m in (row + 1)..<(minRowBck + 3) {
            for n in minColBck..<col {
                if table[m][n] == 0 {
                    if fillPoint(&table, (m,n), &stack, &unfilledMissingSets) { return true }
                }
            }
            for n in (col + 1)..<(minColBck + 3) {
                if table[m][n] == 0 {
                    if fillPoint(&table, (m,n), &stack, &unfilledMissingSets) { return true }
                }
            }
        }
        // Function does not need to end (i.e table is still valid)
        return false
    }
    // O(q) steps -- Get the possible values for this cell
    private func getMissing(_ table: [[Int]], _ loc: (Int,Int)) -> Set<Int> {
        
        var possibleValues: Set<Int> = [1,2,3,4,5,6,7,8,9]
        
        let row = loc.0
        let col = loc.1
        
        for i in 0..<col { // O(8)
            if table[row][i] > 0 {
                possibleValues.remove(table[row][i]) //O(1)
            }
        }
        for i in (col + 1)..<9 {
            if table[row][i] > 0 {
                possibleValues.remove(table[row][i]) //O(1)
            }
        }
        
        for i in 0..<row { // O(8)
            if table[i][col] > 0 {
                possibleValues.remove(table[i][col]) //O(1)
            }
        }
        for i in (row + 1)..<9 {
            if table[i][col] > 0 {
                possibleValues.remove(table[i][col]) //O(1)
            }
        }

        let minRowBck = (row / 3) * 3
        let minColBck = (col / 3) * 3
        
        for m in minRowBck..<row { // O(2)
            for n in minColBck..<col {
                if table[m][n] > 0 {
                    possibleValues.remove(table[m][n]) //O(1)
                }
            }
            for n in (col + 1)..<(minColBck + 3) {
                if table[m][n] > 0 {
                    possibleValues.remove(table[m][n]) //O(1)
                }
            }
        }
        for m in (row + 1)..<(minRowBck + 3) { // O(2)
            for n in minColBck..<col {
                if table[m][n] > 0 {
                    possibleValues.remove(table[m][n]) //O(1)
                }
            }
            for n in (col + 1)..<(minColBck + 3) {
                if table[m][n] > 0 {
                    possibleValues.remove(table[m][n]) //O(1)
                }
            }
        }
        
        return possibleValues
        
    }
    // O(c) steps -- Where c is the number of cells (capped at 81). Get all unfilled cells from the entire table
    private func getAllUnfilledPoints(_ table: [[Int]]) -> [(Int,Int)] {
        // 1 step
        var unfilledPoints: [(Int,Int)] = []
        // 81 * [1 + O(1)] steps
        for i in 0..<9 {
            for j in 0..<9 {
                if table[i][j] == 0 {
                    unfilledPoints.append((i,j))
                }
            }
        }
        // 1 step
        return unfilledPoints
    }
    
    func correctPlacementSolveWithTime( _ table: [[Int]]) {
        DispatchQueue.global().async {
            let allUnfilledPoints = self.getAllUnfilledPoints(table) // O(c)
            let missingTable = self.getUnfilledMissingSets(table, allUnfilledPoints) // O(p * q)
            self.correctPlacementSolve(table,allUnfilledPoints,missingTable)
        }
    }
    // O(p * q) - Get all the possible values for each cell
    private func getUnfilledMissingSets( _ table: [[Int]], _ allUnfilledPoints: [(Int,Int)]) -> [Int:Set<Int>] {
        // 1 step
        var unfilledMissingSets: [Int:Set<Int>] = [:]
        // O(pq) steps
        for i in 0..<allUnfilledPoints.count {
            unfilledMissingSets[allUnfilledPoints[i].0 * 10 + allUnfilledPoints[i].1] = getMissing(table, (allUnfilledPoints[i]))
        }
        // 1 step
        return unfilledMissingSets
    }
    
    private func printUnfilledMissingSets( _ unfilledMissingSets: [Int:Set<Int>]) {
        
        var table: [[[Int]]] = Array(repeating: Array(repeating: [], count: 9), count: 9)
        
        var count = 0
        for (i,v) in unfilledMissingSets {
            table[i/10][i%10] = Array(v).sorted()
            count += v.count
        }
        
        var str = ""

        for row in 0..<9 {
            for col in 0..<9 {
                for i in 1...9 {
                    if table[row][col].contains(i) {
                        str += "\(i)"
                    } else {
                        str += "_"
                    }
                }
                str += ","
                if col % 3 == 2 { str += " " }
            }
            str += "\n"
            if row % 3 == 2 { str += "\n" }
        }
        
        print("\(str)Size is \(count)")
    }
    
    private func printTable( _ table: [[Int]]) {

        var str = ""

        for row in 0..<9 {
            for col in 0..<9 {
                str += "\(table[row][col])"
                if col % 3 == 2 { str += " " }
            }
            str += "\n"
            if row % 3 == 2 { str += "\n" }
        }

        print(str)
        
        print("The solution is valid \(verifySolution(table))")
        
        let timeInterval = Date().timeIntervalSince(start)

        print("This took \(timeInterval.magnitude) seconds.\n\n")
    }
    
    private func verifySolution(_ table: [[Int]]) -> Bool {
        
        for row in 0..<9 {
            var sum = 0
            var possibleValues: Set<Int> = [1,2,3,4,5,6,7,8,9]
            for col in 0..<9 {
                sum += table[row][col]
                possibleValues.remove(table[row][col])
            }
            if sum != 45 || !possibleValues.isEmpty {
                return false
            }
        }
        
        for col in 0..<9 {
            var sum = 0
            var possibleValues: Set<Int> = [1,2,3,4,5,6,7,8,9]
            for row in 0..<9 {
                sum += table[row][col]
                possibleValues.remove(table[row][col])
            }
            if sum != 45 || !possibleValues.isEmpty {
                return false
            }
        }
        
        for b in 0..<9 {
            let minRow = (b / 3) * 3
            let minCol = (b % 3) * 3
            var sum = 0
            var possibleValues: Set<Int> = [1,2,3,4,5,6,7,8,9]
            for row in minRow..<(minRow + 3) {
                for col in minCol..<(minCol + 3) {
                    sum += table[row][col]
                    possibleValues.remove(table[row][col])
                }
            }
            if sum != 45 || !possibleValues.isEmpty {
                return false
            }
        }
        
        return true
        
    }
    
}

func arrayToTable( _ line: String) -> [[Int]] {
    
    var line = line
    
    var table: [[Int]] = []
    for _ in 0..<9 {
        var row: [Int] = []
        for _ in 0..<9 {
            row.append(Int(String(line.removeFirst()))!)
        }
        table.append(row)
    }
    
    return table
}

var start = Date()

const std = @import("std");
const DynamicBitset = std.bit_set.DynamicBitSet;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const assert = std.debug.assert;

fn getMainDiagonalIndex(dim: usize, x: usize, y: usize) usize {
    return (dim - 1) - 1 + x - y;
}

fn getOffDiagonalIndex(x: usize, y: usize) usize {
    return x + y;
}

fn getBlockIndex(x: usize, y: usize) usize {
    return (y / 3) * 3 + x / 3;
}

fn initBitsets(allocator: Allocator, count: usize, size: usize) ![]DynamicBitset {
    var bitsets = try allocator.alloc(DynamicBitset, count);
    for (bitsets) |*bitset| {
        bitset.* = try DynamicBitset.initEmpty(allocator, size);
    }

    return bitsets;
}

fn initCells(allocator: Allocator, dim: usize) ![]usize {
    var cells = try allocator.alloc(usize, dim * dim);
    for (cells) |*cell| {
        cell.* = 0;
    }
    return cells;
}

fn getDiagonalsCount(dim: usize) usize {
    return (dim - 1) * 2 + 1;
}

const Cache = struct {
    // rows[i][v] tells you whether v + 1 is contained on row with index i
    dim: usize,
    rows: []DynamicBitset,
    cols: []DynamicBitset,
    mainDiag: []DynamicBitset,
    offDiag: []DynamicBitset,
    blocks: []DynamicBitset,

    const Self = @This();

    fn init(allocator: Allocator, dim: usize) !Self {
        return .{
            .dim = dim,
            .rows = try initBitsets(allocator, dim, dim),
            .cols = try initBitsets(allocator, dim, dim),
            .mainDiag = try initBitsets(allocator, getDiagonalsCount(dim), dim),
            .offDiag = try initBitsets(allocator, getDiagonalsCount(dim), dim),
            .blocks = try initBitsets(allocator, dim, dim),
        };
    }

    fn set(self: *Self, x: usize, y: usize, value: usize) void {
        self.rows[y].set(value - 1);
        self.cols[x].set(value - 1);
        self.mainDiag[getMainDiagonalIndex(self.dim, x, y)].set(value - 1);
        self.offDiag[getOffDiagonalIndex(x, y)].set(value - 1);
        self.blocks[getBlockIndex(x, y)].set(value - 1);
    }

    fn unset(self: *Self, x: usize, y: usize, value: usize) void {
        self.rows[y].unset(value - 1);
        self.cols[x].unset(value - 1);
        self.mainDiag[getMainDiagonalIndex(self.dim, x, y)].unset(value - 1);
        self.offDiag[getOffDiagonalIndex(x, y)].unset(value - 1);
        self.blocks[getBlockIndex(x, y)].unset(value - 1);
    }

    fn hasValueInRow(self: *const Self, row: usize, value: usize) bool {
        return self.rows[row].isSet(value - 1);
    }

    fn hasValueInColumn(self: *const Self, column: usize, value: usize) bool {
        return self.cols[column].isSet(value - 1);
    }

    fn hasValueInMainDiagonal(self: *const Self, diagonal: usize, value: usize) bool {
        return self.mainDiag[diagonal].isSet(value - 1);
    }

    fn hasValueInOffDiagonal(self: *const Self, diagonal: usize, value: usize) bool {
        return self.offDiag[diagonal].isSet(value - 1);
    }

    fn hasValueInBlock(self: *const Self, index: usize, value: usize) bool {
        return self.blocks[index].isSet(value - 1);
    }
};

pub const Board = struct {
    dim: usize,
    cells: []usize,
    cache: Cache,

    const Self = @This();

    pub fn init(allocator: Allocator, dim: usize) !Self {
        assert(dim % 3 == 0);
        return .{
            .dim = dim,
            .cells = try initCells(allocator, dim),
            .cache = try Cache.init(allocator, dim),
        };
    }

    fn isValidMove(self: *const Self, x: usize, y: usize, value: usize) bool {
        return !self.cache.hasValueInRow(y, value) and
            !self.cache.hasValueInColumn(x, value) and
            !self.cache.hasValueInMainDiagonal(getMainDiagonalIndex(self.dim, x, y), value) and
            !self.cache.hasValueInOffDiagonal(getOffDiagonalIndex(x, y), value) and
            !self.cache.hasValueInBlock(getBlockIndex(x, y), value);
    }

    pub fn set(self: *Self, x: usize, y: usize, value: usize) void {
        assert(value > 0 and value < self.dim);
        if (!self.isValidMove(x, y, value)) {
            std.debug.print("invalid move\n", .{});
            return;
        }

        if (self.cells[y * self.dim + x] != 0) {
            self.cache.unset(x, y, self.cells[y * self.dim + x]);
        }
        self.cache.set(x, y, value);
        self.cells[y * self.dim + x] = value;
    }

    pub fn clear(self: *Self, x: usize, y: usize) void {
        self.cache.unset(x, y, self.cells[y * self.dim + x]);
        self.cells[y * self.dim + x] = 0;
    }

    pub fn print(self: *const Self) void {
        for (0..self.cells.len) |index| {
            if (index != 0 and index % (self.dim) == 0) {
                std.debug.print("\n", .{});
            }
            std.debug.print("{} ", .{self.cells[index]});
        }
        std.debug.print("\n", .{});
    }
};

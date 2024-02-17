const std = @import("std");
const Sudoku = @import("Board.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var board = try Sudoku.Board.init(allocator, 9);
    board.set(1, 2, 1);
    board.set(3, 0, 2);
    board.clear(3, 0);
    board.set(3, 0, 2);
    board.print();
}

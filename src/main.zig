const std = @import("std");
const expect = std.testing.expect;
const net = std.net;
const os = std.posix;

test "create a socket" {
    const socket = try Socket.init("127.0.0.1", 3000);
    try expect(@TypeOf(socket.socket) == std.posix.socket_t);
}

const Socket = struct {
    address: std.net.Address,
    socket: std.posix.socket_t,

    fn init(ip: []const u8, port: u16) !Socket {
        const parsed_address = try std.net.Address.parseIp4(ip, port);
        const sock = try std.posix.socket(std.posix.AF.INET, std.posix.SOCK.DGRAM, 0);
        errdefer os.closeSocket(sock);
        return Socket{ .address = parsed_address, .socket = sock };
    }

    fn bind(self: *Socket) !void {
        try os.bind(self.socket, &self.address.any, self.address.getOsSockLen());
        std.debug.print("Socket created, listening on port 3000\n", .{});
    }

    fn listen(self: *Socket) !void {
        var buffer: [1024]u8 = undefined;

        while (true) {
            const received_bytes = try std.posix.recvfrom(self.socket, buffer[0..], 0, null, null);
            std.debug.print("Received {d} bytes: {s}\n", .{ received_bytes, buffer[0..received_bytes] });
        }
    }
};

fn handle_user_input() void {
    var stdin = std.io.getStdIn().reader();
    var stdout = std.io.getStdOut().writer();

    var input: [256]u8 = undefined;
    var input_buffer = input[0..];

    while (true) {
        try stdout.print("Enter message (type 'exit' to quit): ", .{});
        if (try stdin.readUntilDelimiterOrEof(input_buffer[0..], '\n')) |user_input| {
            var trimmed_input = user_input;
            while (trimmed_input.len > 0 and (trimmed_input[trimmed_input.len - 1] == '\r')) {
                trimmed_input = trimmed_input[0 .. trimmed_input.len - 1];
            }
            if (std.mem.eql(u8, trimmed_input, "exit")) {
                break;
            }
        } else {
            break;
        }
    }
}

pub fn main() !void {
    var name = try Socket.init("127.0.0.1", 3000);
    try name.bind();

    // var listener_thread = try std.Thread.spawn(.{}, Socket.listen, .{&name});
    var input_thread = try std.Thread.spawn(.{}, handle_user_input, .{});

    // try listener_thread.join();
    try input_thread.join();
}

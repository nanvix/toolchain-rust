// Copyright(c) The Maintainers of Nanvix.
// Licensed under the MIT License.

//! Minimal smoke test for the custom Rust toolchain targeting i686-unknown-nanvix.
//!
//! Build with:
//!   cargo +nanvix-x86 build --target i686-unknown-nanvix -Zbuild-std=core,alloc

#![no_std]
#![no_main]

use core::panic::PanicInfo;

#[no_mangle]
pub extern "C" fn _start() -> ! {
    loop {}
}

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}

use std::io::ErrorKind;
use web3::types::Bytes;
use web3::Web3;

pub fn from_hex_char(i: u8) -> i32 {
    if i >= '0' as u8 && i <= '9' as u8 {
        return (i - '0' as u8) as i32;
    }
    if i >= 'a' as u8 && i <= 'f' as u8 {
        return (i - 'a' as u8 + 10) as i32;
    }
    if i >= 'A' as u8 && i <= 'F' as u8 {
        return (i - 'A' as u8 + 10) as i32;
    }
    return -1 as i32;
}

pub fn from_hex(s: &String) -> Result<Bytes, Box<dyn std::error::Error + Send + Sync>> {
    let mut t: u32 = if s.len() >= 2
        && s.bytes().nth(0).expect("Could not parse string") == '0' as u8
        && s.bytes().nth(1).expect("Could not parse string") == 'x' as u8
    {
        2
    } else {
        0
    };
    let mut ret: Vec<u8> = Vec::with_capacity((s.len() - t as usize + 1) / 2);

    if s.len() % 2 == 1 {
        let h: i32 = from_hex_char(s.bytes().nth(t as usize).unwrap() as u8);
        t = t + 1;
        if h != -1 {
            ret.push(h as u8);
        } else {
            return Err(Box::new(std::io::Error::new(
                ErrorKind::InvalidData,
                "Error parsing hex string",
            )));
        }
    }
    for i in (t..s.len() as u32).step_by(2) {
        let h: i32 = from_hex_char(s.bytes().nth(i as usize).unwrap());
        let l: i32 = from_hex_char(s.bytes().nth((i + 1) as usize).unwrap());
        if h != -1 && l != -1 {
            ret.push((h * 16 + l) as u8);
        } else {
            return Err(Box::new(std::io::Error::new(
                ErrorKind::InvalidData,
                "Error parsing hex string",
            )));
        }
    }

    Ok(Bytes(ret))
}

#[allow(dead_code)]
pub fn step_encode_input(
    w3: &Web3<web3::transports::Http>,
    _rw_positions: &Vec<u64>,
    _rw_values: Vec<Bytes>,
    _is_read: Vec<bool>,
) -> Bytes {
    let func_signature = Bytes(Vec::from("step(uint64[],bytes8[],bool[])".as_bytes()));
    let _signature = w3.web3().sha3(func_signature);

    let encode_input: Bytes = Bytes(Vec::new());

    encode_input
}

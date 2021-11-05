use byteorder::ByteOrder;
use std::io::ErrorKind;
use web3::ethabi::ethereum_types::H256;
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

pub async fn step_encode_input(
    w3: &Web3<web3::transports::Http>,
    rw_positions: &Vec<u64>,
    rw_values: &Vec<Bytes>,
    is_read: &Vec<bool>,
) -> Bytes {
    let func_signature = Bytes(Vec::from("step(uint64[],bytes8[],bool[])".as_bytes()));
    let signature = w3
        .web3()
        .sha3(func_signature)
        .await
        .expect("Unable to hash function signature");
    let mut encode_input: Bytes =
        Bytes(vec![signature[0], signature[1], signature[2], signature[3]]);

    let number_of_positions: u32 = rw_positions.len() as u32;
    let number_of_values = rw_values.len() as u32;
    let number_of_reads = is_read.len() as u32;

    let mut buffer: [u8; 32] = [0; 32];
    byteorder::BigEndian::write_u32(&mut buffer[32 - 4..], number_of_positions);
    let number_of_positions_h: H256 = H256(buffer);
    byteorder::BigEndian::write_u32(&mut buffer[32 - 4..], number_of_values);
    let number_of_values_h: H256 = H256(buffer);
    byteorder::BigEndian::write_u32(&mut buffer[32 - 4..], number_of_reads);
    let number_of_reads_h: H256 = H256(buffer);

    // Offset for rw_positions
    let positions_offset: u32 = (encode_input.0.len() - 4 + 32 * 3) as u32;
    byteorder::BigEndian::write_u32(&mut buffer[32 - 4..], positions_offset);
    let positions_offset_h: H256 = H256(buffer);
    encode_input.0.extend_from_slice(&positions_offset_h[..]);

    // Offset for rw_values
    let values_offset = positions_offset + 32 * (1 + number_of_positions);
    byteorder::BigEndian::write_u32(&mut buffer[32 - 4..], values_offset as u32);
    let values_offset_h: H256 = H256(buffer);
    encode_input.0.extend_from_slice(&values_offset_h[..]);

    // Offset for is_read
    let read_offset = values_offset + 32 * (1 + number_of_values);
    byteorder::BigEndian::write_u32(&mut buffer[32 - 4..], read_offset as u32);
    let read_offset_h: H256 = H256(buffer);
    encode_input.0.extend_from_slice(&read_offset_h[..]);

    encode_input.0.extend_from_slice(&number_of_positions_h[..]);
    for i in 0..number_of_positions {
        byteorder::BigEndian::write_u64(&mut buffer[32 - 8..], rw_positions[i as usize]);
        let position: H256 = H256(buffer);
        encode_input.0.extend_from_slice(&position[..]);
    }

    encode_input.0.extend_from_slice(&number_of_values_h[..]);
    for i in 0..number_of_values {
        //let value = &rw_values[i as usize];
        encode_input
            .0
            .extend_from_slice(&(rw_values[i as usize].0)[..]);
        encode_input
            .0
            .resize(encode_input.0.len() + 32 - rw_values[i as usize].0.len(), 0);
    }

    encode_input.0.extend_from_slice(&number_of_reads_h[..]);
    for i in 0..number_of_reads {
        byteorder::BigEndian::write_u64(&mut buffer[32 - 8..], is_read[i as usize] as u64);
        let read: H256 = H256(buffer);
        encode_input.0.extend_from_slice(&read[..]);
    }

    encode_input
}

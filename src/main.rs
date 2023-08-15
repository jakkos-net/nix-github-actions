fn main(){
    println!("1 + 1 = {}", calc());
}

fn calc() -> u32{
    1 + 1
}

#[cfg(test)]
mod tests {
    use crate::calc;
   #[test]
   fn test_calc(){
        assert_eq!(calc(), 2);
   }
}

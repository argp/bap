open Printf
open Libbfd

let rec print_sections sections =
    match sections with
    | []                -> printf "\n";
    | section :: tail   ->
            let name = bfd_section_get_name section in
            let vma = bfd_section_get_vma section in
            let size = bfd_section_get_size section in
            printf "[+] section name: %s\n" name;
            printf "[+] section start: %Lx\n" vma;
            printf "[+] section size: %Ld\n\n" size;
            print_sections tail

let parse_exe fname =
    let bin = Asmir.open_program fname in
    let sections = Asmir.get_all_asections bin in
    let sections = Array.to_list sections in
    sections

let main () = 
    let argc = Array.length Sys.argv in

    if argc > 1 then
        let filename = Sys.argv.(1) in
        let sections = parse_exe filename in
        print_sections sections;
    else
        printf "[*] usage: %s <executable file>\n" Sys.argv.(0)

let _ = main ()

(* EOF *)

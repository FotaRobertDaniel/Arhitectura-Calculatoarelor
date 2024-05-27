`timescale 1ns / 1ps

module process(
    input clk,                // clock 
    input [23:0] in_pix,    // valoarea pixelului de pe pozitia [in_row, in_col] din imaginea de intrare (R 23:16; G 15:8; B 7:0)
    output reg [5:0] row, col,     // selecteaza un rand si o coloana din imagine
    output reg out_we,             // activeaza scrierea pentru imaginea de iesire (write enable)
    output reg [23:0] out_pix,    // valoarea pixelului care va fi scrisa in imaginea de iesire pe pozitia [out_row, out_col] (R 23:16; G 15:8; B 7:0)
    output reg mirror_done,        // semnaleaza terminarea actiunii de oglindire (activ pe 1)
    output reg gray_done,        // semnaleaza terminarea actiunii de transformare in grayscale (activ pe 1)
    output reg filter_done);    // semnaleaza terminarea actiunii de aplicare a filtrului de sharpness (activ pe 1)

// TODO add your finite state machines here

	reg [5:0] index_row = 0 ,index_col = 0;
   reg [5:0] state = 0, next_state = 0;

	reg[24:0] temp_pix_low = 0, temp_pix_high = 0;
	reg[23:0] temp_pix = 0;
	reg[7:0] MAX = 0 , MIN = 0;
	reg[8:0] medie = 0;
	reg[7:0] r = 0 , g = 0 , b = 0;
	
	reg [2:0] filter_state = 0;


   initial begin 
      
		index_row = 0;
		index_col = 0;
		row = 0;
		col = 0;
		mirror_done = 0;
		gray_done = 0;
      filter_done = 0; 
		out_we = 0;
	
	end

	

   always @(posedge clk) begin
   
	state = next_state;

       case(state) 
		 // Mirror image
			0 : begin // Initializare si asteptare a semnalului de activare
						
							
								out_we = 0;    
								
								row = index_row;
								col = index_col; 
								next_state = 1;
								
								end 
								
			1 : begin // Salvare valoare pixel în timpul oglinzii
		
								    
								
								temp_pix_low = in_pix;
								
								next_state = 2;
								
								end 					
			

							
			2 : begin // Calculare noua pozitie de oglindire (pe verticala)
		
								
								
								row = 63 - index_row;
								
								next_state = 3;
								
								end 
			
			3 : begin //  Salvare a doua valoare de pixel pentru oglindire
								
								
								temp_pix_high = in_pix;
								
								next_state = 4;
								
								end 
			
			4 : begin // Scriere prima valoare în imaginea oglinzita
								out_we = 1;
								
								out_pix = temp_pix_low;
								
								next_state = 5;
								
								end 
								
			5 : begin // Dezactivare scriere si actualizare pozitie pentru a scrie a doua valoare	
								out_we = 0;
								
								row = index_row;
								
								next_state = 6;
				
								end 
			6: begin // Scriere a doua valoare în imaginea oglinzita
								out_we = 1;
								
								out_pix = temp_pix_high;
								
								next_state = 7;
		 
								end 
								
			7: begin // Dezactivare scriere si avansare coloana
							
							out_we = 0;
							index_col = index_col + 1;
							next_state = 8;
							
							end 
			
			8: begin // Verificare daca este finalul randului sau trecerea la urmatorul rand
							
							if(index_col == 0) begin
							
								index_row  = index_row + 1;
								
								
							end
							next_state = 9;
							
							end 
			9: begin // Verificare daca s-a terminat oglindirea intregi imagini
						
						
						
						
						
						if(index_col == 0 && index_row == 32) begin 
								mirror_done = 1;
								index_col = 0;
								index_row = 0;
								next_state = 10;
						end else begin 
										next_state = 0;
									end 
						
						 
						
					end
					
			// Grayscale transformation			
			10  : begin // Initializare si asteptare pentru transformarea in grayscale
			
						row = index_row;
						col = index_col;
						next_state = 11;
							
					end 
					
			11	: begin // Salvare valoare pixel pentru transformarea in grayscale
			
						temp_pix = in_pix;
						next_state = 12;
						
					end
					
			12 : begin // Separarea canalelor de culoare r, g, b
			
						r = temp_pix >> 16;
						g = temp_pix >> 8;
						b = temp_pix;
						next_state = 13;
					
					end
					
			13 : begin // Calculare valorile minimale si maxime ale canalelor de culoare
						
						MIN = (r < g) ? (r < b) ? r : b : (g < b) ? g : b;
						MAX = (r > g) ? (r > b) ? r : b : (g > b) ? g : b;
						next_state = 14;
						
					end
					
			14 : begin // Calculare valoare medie intre MIN si MAX
			
						medie = (MAX + MIN)/2;
						temp_pix = 0;
						next_state = 15;
						
					end
					
			15 : begin // Actualizare valoare pixel cu valoarea medie în canalul G
			
						temp_pix = medie << 8;
						next_state = 16;
						
					end
					
			16 : begin // Scriere valoare pixel in imaginea finala
					
						out_we = 1;
						out_pix = temp_pix;
						next_state = 17;
					
					end
					
			17: begin // Dezactivare scriere si avansare coloana
							
							out_we = 0;
							index_col = index_col + 1;
							next_state = 18;
							
							end 
			
			18: begin // Verificare daca este finalul randului sau trecerea la urmatorul rand
							
							if(index_col == 0) begin
							
								index_row  = index_row + 1;
								
								
							end
							next_state = 19;
							
							end 
			19: begin // Verificare daca s-a terminat transformarea in Grayscale
						
						if(index_col == 0 && index_row == 0) begin 
								gray_done = 1;
								index_col = 0;
								index_row = 0;
								next_state = 20;
						end else begin 
										next_state = 10;
									end 
					end



		// Sharpness filter
		 20: begin // Initializare pentru aplicarea filtrului de sharpness
			  
			  filter_done = 0; 
			  index_col = 0;  
			  next_state = 21;
		 end

			21: begin // Initializare pentru starea filtrului de sharpness
					
					 filter_state = 0;
					 next_state = 22;
					end

			22: begin // Dezactivare scriere si actualizare pozitie pentru filtrul de sharpness
						
						 out_we = 0; 
						 row = index_row;
						 col = index_col;
						 next_state = 23;
					end

			23: begin // Salvare valoare pixel pentru filtrul de sharpness
						
						 temp_pix_low = in_pix;
						 next_state = 24;
					end

			24: begin // Activare filtru de sharpness
						 
						 filter_state = 2;
						 next_state = 25;
					end

			25: begin // Salvare a doua valoare de pixel pentru filtrul de sharpness
					 temp_pix_high = in_pix;
					 if (index_row > 0 && index_row < 63 && index_col > 0 && index_col < 63) begin
						  temp_pix = temp_pix_low + (9 * temp_pix_high) - in_pix;

						  if (temp_pix < 0) begin
								temp_pix = 0;
						  end else if (temp_pix > 255) begin
								temp_pix = 255;
						  end
					 end else begin
						  temp_pix = temp_pix_high;
					 end

					 out_we = 1;
					 out_pix = temp_pix;
					 next_state = 26;
				end

			26: begin
						 
						 out_we = 0;
						 filter_state = 0;
						 index_col = index_col + 1;
						 next_state = (index_col == 0) ? 27 : 22;
					end

		27: begin // Verificare daca s-a terminat filtrul de sharpness
			
			if (index_row == 0 && index_col == 0) begin
				filter_done = 1; 
				index_col = 0;
				index_row = 0;
				next_state = 28;
			end else begin
				next_state = 21;
			end
		end

		28: begin
			
		end

				

		endcase
	end

endmodule

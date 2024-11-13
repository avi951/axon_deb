#!/bin/env bash
TEST_COUNT=""

if [[ -f /opt/test_axon.txt ]]; then
	TEMP=`expr $(cat /opt/test_axon.txt | cut -c 2) + 1`
	TEST_COUNT="s$TEMP"
else
	TEST_COUNT="s0"
fi

#mate-terminal -x sh -c "echo $TEST_COUNT; bash"
DISPLAY=:0 mate-terminal -x bash -c "
	sleep 3; 
	cd /test; 
	status=$(cat "/opt/test_axon.txt")
	echo -n 'By default running $TEST_COUNT, do you want to start from s0? [y/N]: ';
    var=\$(echo \"\$var\" | tr '[:upper:]' '[:lower:]') # Convert to lowercase
	read var; 
	echo \$var; 
    
	if [[ \"\$var\" = \"y\" ]]; then
	        if [[ \"\$status\" != \"s0\" ]]; then
        	 	echo -n 'Are you sure you want to start from s0 again? [y/N]: ';
            		again=\$(echo \"\$again\" | tr '[:upper:]' '[:lower:]') 
            		read again;
	    	    	if [[ \"\$again\" = \"y\" ]]; then
    	    	        	./axon-test.sh s0; 
	    		    	echo s0 | sudo tee /opt/test_axon.txt > /dev/null; 
            		else
            	        	./axon-test.sh $TEST_COUNT; 
            	        	echo $TEST_COUNT | sudo tee /opt/test_axon.txt > /dev/null; 
            		fi;
       		else     
		    ./axon-test.sh $TEST_COUNT;
        	    echo $TEST_COUNT | sudo tee /opt/test_axon.txt > /dev/null;
        	fi;
	else
        	if [[ \"\$status\" = \"s6\" ]]; then
        	    echo -n '>>>>>>>>>>>>>>>>>>>>>';
                echo -n 'REMOVE TEST SCRIPT FROM AXON';
                echo -n '>>>>>>>>>>>>>>>>>>>>>';
                #rm -rf /opt/test_axon.txt
                #echo -n 'Are you sure you want to delete script ? [y/N]';
                #read del;
                #del=\$(echo \"\$del\" | tr '[:upper:]' '[:lower:]')
                #if [[ \"\$read\" = \"y\" ]]; then
        	else    
        	    ./axon-test.sh $TEST_COUNT; 
        	    echo $TEST_COUNT | sudo tee /opt/test_axon.txt > /dev/null; 
        	fi
	fi;
        echo 'Want to check Manually ? [y/N]?'
	read ask;
	ask=\$(echo \"\$ask\" | tr '[:upper:]' '[:lower:]') # Convert to lowercase
 	if [[ \"\$ask\" = \"y\" ]]; then
		while :
		do
			cd /test
			./axon-test.sh
			echo 'Press 'q' to quit or any other key to continue.'
			read  user_input  # Read one character without Enter
        		if [[ \"\$user_input\" = \"q\" ]]; then
        		    break  # Exit the loop if 'q' is pressed
        		fi
		done
	else
		continue
	fi	
	echo -n 'poweroff [y/N]: '; 
	read var;
    var=\$(echo \"\$var\" | tr '[:upper:]' '[:lower:]') # Convert to lowercase
	if [[ \"\$var\" = \"n\" ]]; then
	        echo -n 'Are you sure, you do not want to poweroff? [y/N]';
		read last;
		if [[ \"\$last\" = \"y\" ]]; then
			exit 1	
		else
			sudo poweroff
		fi;
	else	
		sudo poweroff; 
	fi
"

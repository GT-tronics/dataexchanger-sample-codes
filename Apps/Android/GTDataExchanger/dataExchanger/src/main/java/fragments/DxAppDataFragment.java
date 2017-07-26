package fragments;

import android.annotation.SuppressLint;
import android.graphics.Color;
import android.os.Bundle;
import android.util.Log;
import android.view.KeyEvent;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;

import com.gttronics.ble.blelibrary.BleDevice;
import com.gttronics.ble.dataexchanger.R;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;


/**
 * Created by EGUSI16 on 11/22/2016.
 */

public class DxAppDataFragment extends DxAppFragment{

    private View root;
    private boolean hex;

    // Store instance variables based on arguments passed
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    }

    // Inflate the view for the fragment based on layout XML
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        root = inflater.inflate(R.layout.fragment_data, container, false);

        imageViewBLE = (ImageView) getActivity().findViewById(R.id.imageViewBLE);
        editTextRx = (EditText) root.findViewById(R.id.editTextRx);
        editTextTx = (EditText) root.findViewById(R.id.editTextTx);
        disconnectBtn = getActivity().findViewById(R.id.discounnect);
        hexBtn = (TextView) getActivity().findViewById(R.id.hexBtn);
        hexBtn.setVisibility(View.VISIBLE);
        hex = hexBtn.getText().toString().equals("Hex");
        header = (RelativeLayout) getActivity().findViewById(R.id.discounnect_btn_container);
        header.setVisibility(View.VISIBLE);

        startBle();


        editTextRx.setKeyListener(null);
        editTextTx.setOnKeyListener(new View.OnKeyListener() {
            public boolean onKey(View v, int keyCode, KeyEvent event) {

                String txString = (editTextTx.getText().toString());
                if (event.getAction() == KeyEvent.ACTION_UP )
                {
                    if (keyCode == KeyEvent.KEYCODE_ENTER)
                    {
                        // Send data to the connected device
                        byte[] bytes = txString.getBytes();
                        if( bytes.length > 0 )
                        {
                            dxAppController.sendData(bytes);
                        }
                        Log.d("MAIN", "Tx Data [" + txString + "]");
                    }
                    else if( keyCode == KeyEvent.KEYCODE_DEL )
                    {
                        editTextTx.setText("");
                    }
                }

                return true;
            }
        });
        disconnectBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                if (dxAppController != null)
                    getActivity().runOnUiThread(new Runnable() {
                        public void run() {
                            imageViewBLE.setColorFilter(Color.rgb(0, 0, 0));
                        }
                    });
                    dxAppController.disconnect();
            }
        });

        hexBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                if(hexBtn.getText().toString().equals("Text")){
                    hexBtn.setText("Hex");
                    hex = true;
                } else {
                    hexBtn.setText("Text");
                    hex = false;
                }
            }
        });

        return root;
    }


    @Override
    public void onRxDataAvailable(BleDevice dev, byte[] data)
    {
        super.onRxDataAvailable(dev, data);
        // Place your code here to handle the received data
        //

        getActivity().runOnUiThread(new Runnable() {
            public void run() {
                Date currentLocalTime = Calendar.getInstance().getTime();
                SimpleDateFormat simpleDateFormat = new java.text.SimpleDateFormat("mm::ss::SSS");
                String formattedCurrentDate = simpleDateFormat.format(currentLocalTime);

                String rxString = editTextRx.getText().toString()+ "\n" + formattedCurrentDate + ":" + new String(rxData);

                /*if (!hex){
                    rxString.replaceAll("\\\\", "<DataExchanger\\>");
                    rxString.replaceAll("\\r", "\r");
                    rxString.replaceAll("\\n", "\n");
                    rxString.replaceAll("\\t", "\t");
                    rxString.replaceAll("\\b","\b");

                    String matchStr = "\\\\x([0-9ABCDEFabcdef]{2})";
                    List<String> allMatches = new ArrayList<String>();
                    Matcher m = Pattern.compile(rxString).matcher(matchStr);
                    while(m.find()){
                        allMatches.add(m.group());
                    }
                    for(int i = 0; i<allMatches.size();i++){

                    }
                }*/
                editTextRx.setText(rxString);
                Log.d("MAIN", "Rx Data [" + new String(rxData) +"]");
            }
        });

    }

    @Override
    public boolean startBle() {
        boolean started = super.startBle();
        if (!started) return false;
        if (dxAppController == null || !dxAppController.isConnected()) {

            getActivity().runOnUiThread(new Runnable() {
                @SuppressLint("WrongConstant")
                public void run() {
                    imageViewBLE.setColorFilter(Color.rgb(0,0,0));
                    editTextRx.setText("Searching for devices ...");
                    /*editTextTx.setText("");

                    editTextTx.requestFocus();

                    editTextTx.setVisibility(View.GONE);
                    textViewTx.setVisibility(View.GONE);*/
                }
            });

            // Start Device Discovery

            dxAppController.enableTxCreditNoti(true);
            dxAppController.enableRxNoti(true);
            dxAppController.enableRx2Noti(true);
            dxAppController.startScan();
        }
        else {
            onAllProfilesReady(null, true);
        }
        return true;
    }

    @Override
    public void onResume() {
        super.onResume();
        startBle();
    }
}

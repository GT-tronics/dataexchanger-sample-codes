package fragments;

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
import android.widget.ScrollView;
import android.widget.TextView;

import com.gttronics.ble.blelibrary.BleDevice;
import com.gttronics.ble.dataexchanger.R;

import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;


/**
 * Created by EGUSI16 on 11/21/2016.
 */

public class DxAppCommandFragment extends DxAppFragment {

    private View root;

    // Store instance variables based on arguments passed
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    }

    // Inflate the view for the fragment based on layout XML
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        root = inflater.inflate(R.layout.fragment_command, container, false);

        imageViewBLE = (ImageView) getActivity().findViewById(R.id.imageViewBLE);
        editTextRx = (EditText) root.findViewById(R.id.editTextRx);
        editTextTx = (EditText) root.findViewById(R.id.editTextTx);
        scrollViewRx = (ScrollView) root.findViewById(R.id.scrollViewRx);
        disconnectBtn = getActivity().findViewById(R.id.discounnect);
        hexBtn = (TextView) getActivity().findViewById(R.id.hexBtn);
        hexBtn.setVisibility(View.GONE);
        header = (RelativeLayout) getActivity().findViewById(R.id.discounnect_btn_container);
        header.setVisibility(View.VISIBLE);


        startBle();

        editTextRx.setKeyListener(null);

        editTextTx.setOnKeyListener(new View.OnKeyListener() {
            public boolean onKey(View v, int keyCode, KeyEvent event) {

                String txString = (editTextTx.getText().toString()) + "\r\n";
                if (event.getAction() == KeyEvent.ACTION_UP )
                {
                    if (keyCode == KeyEvent.KEYCODE_ENTER)
                    {
                        // Send data to the connected device
                        byte[] bytes = txString.getBytes();
                        if( bytes.length > 0 )
                        {
                            boolean succeed = dxAppController.sendCmd(bytes);
                            Log.d("MAIN", "Tx Data [" + txString + "] " + (succeed?"succeed":"failed"));
                        }
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

        return root;
    }

    @Override
    public void onRx2DataAvailable(BleDevice dev, byte[] data) {
        super.onRx2DataAvailable(dev, data);

        getActivity().runOnUiThread(new Runnable() {
            public void run() {
                Date currentLocalTime = Calendar.getInstance().getTime();
                SimpleDateFormat simpleDateFormat = new java.text.SimpleDateFormat("mm::ss::SSS");
                String formattedCurrentDate = simpleDateFormat.format(currentLocalTime);

                String rxString =  editTextRx.getText().toString() + "\n" + formattedCurrentDate + ":" + new String(rxData);

                editTextRx.setText(rxString);
                //scroll down to the botto
                scrollViewRx.post(new Runnable() {
                    @Override
                    public void run() {
                        scrollViewRx.fullScroll(View.FOCUS_DOWN);
                    }
                });
            }
        });
    }

    @Override
    public boolean startBle() {
        boolean started = super.startBle();
        if (!started) return false;
        if (dxAppController == null || !dxAppController.isConnected()) {

            getActivity().runOnUiThread(new Runnable() {
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
            editTextTx.setText("AT+");
        }
        return false;
    }

    @Override
    public void onResume() {
        super.onResume();
        startBle();
    }
}

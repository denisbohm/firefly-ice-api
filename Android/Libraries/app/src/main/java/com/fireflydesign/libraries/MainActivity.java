package com.fireflydesign.libraries;

import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothManager;
import android.content.Context;
import android.os.Bundle;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.ArrayAdapter;
import android.widget.CheckBox;
import android.widget.ListView;
import android.widget.ProgressBar;
import android.widget.TextView;

import com.fireflydesign.fireflydevice.FDDetour;
import com.fireflydesign.fireflydevice.FDError;
import com.fireflydesign.fireflydevice.FDFireflyDeviceLogger;
import com.fireflydesign.fireflydevice.FDFireflyIce;
import com.fireflydesign.fireflydevice.FDFireflyIceChannel;
import com.fireflydesign.fireflydevice.FDFireflyIceChannelBLE;
import com.fireflydesign.fireflydevice.FDFireflyIceDiagnostics;
import com.fireflydesign.fireflydevice.FDFireflyIceDirectTestModeReport;
import com.fireflydesign.fireflydevice.FDFireflyIceHardwareId;
import com.fireflydesign.fireflydevice.FDFireflyIceLock;
import com.fireflydesign.fireflydevice.FDFireflyIceLogging;
import com.fireflydesign.fireflydevice.FDFireflyIceManager;
import com.fireflydesign.fireflydevice.FDFireflyIceObserver;
import com.fireflydesign.fireflydevice.FDFireflyIcePower;
import com.fireflydesign.fireflydevice.FDFireflyIceReset;
import com.fireflydesign.fireflydevice.FDFireflyIceRetained;
import com.fireflydesign.fireflydevice.FDFireflyIceSectorHash;
import com.fireflydesign.fireflydevice.FDFireflyIceSensing;
import com.fireflydesign.fireflydevice.FDFireflyIceSimpleTask;
import com.fireflydesign.fireflydevice.FDFireflyIceStorage;
import com.fireflydesign.fireflydevice.FDFireflyIceUpdateCommit;
import com.fireflydesign.fireflydevice.FDFireflyIceVersion;
import com.fireflydesign.fireflydevice.FDFirmwareUpdateTask;
import com.fireflydesign.fireflydevice.FDHelloTask;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

public class MainActivity extends Activity implements FDFireflyIceManager.Delegate, FDFireflyIceObserver, FDFirmwareUpdateTask.Delegate {

    FDFireflyIceManager fireflyIceManager;
    Map<String, Map<String, Object>> discovered;
    List<String> listViewItems;
    FDFireflyIce fireflyIce;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        discovered = new HashMap<>();
        listViewItems = new ArrayList<String>();
        ListView listView = (ListView)findViewById(R.id.listView);
        ArrayAdapter<String> adapter = new ArrayAdapter<String>(this, android.R.layout.simple_list_item_single_choice, listViewItems);
        listView.setAdapter(adapter);

        UUID serviceUUID = UUID.fromString("310a0001-1b95-5091-b0bd-b7a681846399"); // Firefly Ice
        BluetoothManager bluetoothManager = (BluetoothManager)getSystemService(Context.BLUETOOTH_SERVICE);
        BluetoothAdapter bluetoothAdapter = bluetoothManager.getAdapter();
        if (bluetoothAdapter != null) {
            fireflyIceManager = new FDFireflyIceManager(this, bluetoothAdapter, serviceUUID, this);
        } else {
            TextView statusTextView = (TextView)findViewById(R.id.statusTextView);
            statusTextView.setText("Bluetooth is not available!");
        }
    }

    public void discovered(FDFireflyIceManager manager, BluetoothDevice bluetoothDevice) {
        Map map = discovered.get(bluetoothDevice.getAddress());
        if (map != null) {
            return;
        }

        FDFireflyIce fireflyIce = new FDFireflyIce(this);
        fireflyIce.observable.addObserver(this);
        FDFireflyIceChannelBLE channel = new FDFireflyIceChannelBLE(this, "310a0001-1b95-5091-b0bd-b7a681846399", bluetoothDevice);
        fireflyIce.addChannel(channel, "BLE");

        map = new HashMap();
        map.put("bluetoothDevice", bluetoothDevice);
        map.put("fireflyIce", fireflyIce);
        discovered.put(bluetoothDevice.getAddress(), map);

        // add to end of list
        ListView listView = (ListView)findViewById(R.id.listView);
        ArrayAdapter<String> adapter = (ArrayAdapter<String>)listView.getAdapter();
        adapter.add(bluetoothDevice.getAddress());
    }

    public void onScanCheckBoxChange(View view) {
        CheckBox checkBox = (CheckBox)view;
        fireflyIceManager.setDiscovery(checkBox.isChecked());
    }

    public void onConnectButtonClicked(View view) {
        if (fireflyIce != null) {
            return;
        }

        FDFireflyDeviceLogger.debug(null, "opening firefly device");
        ListView listView = (ListView)findViewById(R.id.listView);
        int position = listView.getCheckedItemPosition();
        String address = listViewItems.get(position);
        Map map = discovered.get(address);
        fireflyIce = (FDFireflyIce)map.get("fireflyIce");
        FDFireflyIceChannelBLE channel = (FDFireflyIceChannelBLE)fireflyIce.channels.get("BLE");
        channel.open();
    }

    public void onDisconnectButtonClicked(View view) {
        if (fireflyIce == null) {
            return;
        }

        FDFireflyDeviceLogger.debug(null, "closing firefly device");
        for (FDFireflyIceChannel channel : fireflyIce.channels.values()) {
            channel.close();
        }
        fireflyIce = null;
    }

    public void onIlluminateClicked(View view) {
        if (fireflyIce == null) {
            return;
        }

        FDFireflyDeviceLogger.debug(null, "illuminating firefly device");
        final FDFireflyIceChannel channel = fireflyIce.channels.get("BLE");
        FDFireflyIceSimpleTask task = new FDFireflyIceSimpleTask(fireflyIce, channel, new FDFireflyIceSimpleTask.Delegate() {
            public void run() {
                fireflyIce.coder.sendIdentify(channel, 5.0);
            }
        });
        fireflyIce.executor.execute(task);
    }

    public void onFirmwareUpdateButtonClicked(View view) {
        if (fireflyIce == null) {
            return;
        }

        FDFireflyDeviceLogger.debug(null, "updating firefly device");
        FDFireflyIceChannel channel = fireflyIce.channels.get("BLE");
        FDFirmwareUpdateTask task = FDFirmwareUpdateTask.firmwareUpdateTask(fireflyIce, channel, getResources());
        task.delegate = this;
        task.downgrade = true;
        fireflyIce.executor.execute(task);
    }

    public void firmwareUpdateTaskProgress(FDFirmwareUpdateTask task, float progress) {
        ProgressBar progressBar = (ProgressBar)findViewById(R.id.progressBar);
        progressBar.setProgress((int)(progress * 100));
    }

    public void firmwareUpdateTaskComplete(FDFirmwareUpdateTask task, boolean isFirmwareUpToDate) {

    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        // Inflate the menu; this adds items to the action bar if it is present.
        getMenuInflater().inflate(R.menu.menu_main, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        // Handle action bar item clicks here. The action bar will
        // automatically handle clicks on the Home/Up button, so long
        // as you specify a parent activity in AndroidManifest.xml.
        int id = item.getItemId();

        //noinspection SimplifiableIfStatement
        if (id == R.id.action_settings) {
            return true;
        }

        return super.onOptionsItemSelected(item);
    }

    @Override
    public void fireflyIceStatus(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceChannel.Status status) {
        if (status == FDFireflyIceChannel.Status.Open) {
            FDFireflyDeviceLogger.info(null, "executing hello task");
            fireflyIce.executor.execute(new FDHelloTask(fireflyIce, channel, null));
        }
    }

    @Override
    public void fireflyIceDetourError(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDDetour detour, FDError error) {

    }

    @Override
    public void fireflyIcePing(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, byte[] data) {

    }

    @Override
    public void fireflyIceVersion(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceVersion version) {

    }

    @Override
    public void fireflyIceHardwareId(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceHardwareId hardwareId) {

    }

    @Override
    public void fireflyIceBootVersion(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceVersion bootVersion) {

    }

    @Override
    public void fireflyIceDebugLock(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, boolean debugLock) {

    }

    @Override
    public void fireflyIceTime(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, double time) {

    }

    @Override
    public void fireflyIcePower(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIcePower power) {

    }

    @Override
    public void fireflyIceSite(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, String site) {

    }

    @Override
    public void fireflyIceReset(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceReset reset) {

    }

    @Override
    public void fireflyIceStorage(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceStorage storage) {

    }

    @Override
    public void fireflyIceMode(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, int mode) {

    }

    @Override
    public void fireflyIceTxPower(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, int txPower) {

    }

    @Override
    public void fireflyIceLock(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceLock lock) {

    }

    @Override
    public void fireflyIceLogging(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceLogging logging) {

    }

    @Override
    public void fireflyIceName(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, String name) {

    }

    @Override
    public void fireflyIceDiagnostics(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceDiagnostics diagnostics) {

    }

    @Override
    public void fireflyIceRetained(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceRetained retained) {

    }

    @Override
    public void fireflyIceDirectTestModeReport(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceDirectTestModeReport directTestModeReport) {

    }

    @Override
    public void fireflyIceExternalHash(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, byte[] externalHash) {

    }

    @Override
    public void fireflyIcePageData(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, byte[] pageData) {

    }

    @Override
    public void fireflyIceSectorHashes(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceSectorHash[] sectorHashes) {

    }

    @Override
    public void fireflyIceUpdateCommit(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceUpdateCommit updateCommit) {

    }

    @Override
    public void fireflyIceSensing(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceSensing sensing) {

    }

    @Override
    public void fireflyIceSync(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, byte[] syncData) {

    }

}

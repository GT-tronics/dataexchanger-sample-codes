//
//  MainActivity.java
//  DataExchanger
//
//  Created by Ming Leung on 2014-08-01.
//  Copyright (c) 2014 GT-Tronics HK Ltd. All rights reserved.
//b

package com.gttronics.ble.dataexchanger;

import java.util.List;

import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentActivity;
import android.support.v4.app.FragmentManager;
import android.support.v4.app.FragmentPagerAdapter;
import android.support.v4.app.FragmentTransaction;
import android.support.v4.view.ViewPager;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;

import com.gttronics.ble.blelibrary.dataexchanger.DxAppController;

import fragments.DxAppCommandFragment;
import fragments.DxAppDataFragment;
import fragments.DxAppFragment;

public class MainActivity extends FragmentActivity {

	ViewPager pager;
	PagerAdapter pagerAdapter;
	List<DxAppFragment> fragments;

	View dataChannelBtn;
	View commandChannelBtn;

	int currentChannel = 1;

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_main);

		dataChannelBtn = findViewById(R.id.data_channel);
		commandChannelBtn = findViewById(R.id.command_channel);

//		pager = (ViewPager) findViewById(R.id.viewPager);
		//fragments = new ArrayList<>();

		//fragments.add(new DxAppDataFragment());
		//fragments.add(new DxAppCommandFragment());
		//fragments.add(new DxAppTransferTestFragment());
//		fragments.add(new DxAppFirmMgtFragment());
//		fragments.add(new DxAppFirmActFragment());
		//fragments.add(new DxAppFirmActFragment());

		dataChannelBtn.setOnClickListener(new View.OnClickListener() {
			@Override
			public void onClick(View view) {
				if (currentChannel != 1) {
					switchFragment(new DxAppDataFragment());
					currentChannel = 1;
				}
			}
		});

		commandChannelBtn.setOnClickListener(new View.OnClickListener() {
			@Override
			public void onClick(View view) {
				if (currentChannel != 2) {
					switchFragment(new DxAppCommandFragment());
					currentChannel = 2;
				}
			}
		});


		switchFragment(new DxAppDataFragment());

//		pagerAdapter = new PagerAdapter(getSupportFragmentManager(), fragments);
//		pager.setAdapter(pagerAdapter);
//		pager.setOnPageChangeListener(pagerAdapter);
	}

	public void switchFragment(DxAppFragment fragment) {
		FragmentManager fm = getSupportFragmentManager();
		FragmentTransaction transaction = fm.beginTransaction();
		transaction.replace(R.id.fragment_container, fragment);
		transaction.commit();
	}

	@Override
	public void onDestroy() {
		super.onDestroy();
		DxAppController dxAppController = DxAppController.getInstance();
		if (dxAppController != null) {
			try {
				dxAppController.close();
			}
			catch (Exception e) {
				e.printStackTrace();
			}
		}
	}

	@Override
	public boolean onCreateOptionsMenu(Menu menu) {
		// Inflate the menu; this adds items to the action bar if it is present.
		getMenuInflater().inflate(R.menu.main, menu);
		return true;
	}

	@Override
	public boolean onOptionsItemSelected(MenuItem item) {
		// Handle action bar item clicks here. The action bar will
		// automatically handle clicks on the Home/Up button, so long
		// as you specify a parent activity in AndroidManifest.xml.
		int id = item.getItemId();
		if (id == R.id.action_settings) {
			return true;
		}
		return super.onOptionsItemSelected(item);
	}
	
	private class PagerAdapter extends FragmentPagerAdapter implements ViewPager.OnPageChangeListener {

		private List<DxAppFragment> fragments;
		/**
		 * @param fm
		 * @param fragments
		 */
		public PagerAdapter(FragmentManager fm, List<DxAppFragment> fragments) {
			super(fm);
			this.fragments = fragments;
		}
		/* (non-Javadoc)
         * @see android.support.v4.app.FragmentPagerAdapter#getItem(int)
         */
		@Override
		public Fragment getItem(int position) {
			return this.fragments.get(position);
		}

		/* (non-Javadoc)
         * @see android.support.v4.view.PagerAdapter#getCount()
         */
		@Override
		public int getCount() {
			return this.fragments.size();
		}

		@Override
		public void onPageScrolled(int position, float positionOffset, int positionOffsetPixels) {

		}

		@Override
		public void onPageSelected(int i) {
			fragments.get(i).startBle();

		}

		@Override
		public void onPageScrollStateChanged(int state) {

		}
	}


}

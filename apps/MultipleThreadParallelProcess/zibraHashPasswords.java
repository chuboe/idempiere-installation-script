package com.zibra.convertpasswordtohash.process;

import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.logging.Level;

import org.adempiere.exceptions.AdempiereException;
import org.compiere.model.MSysConfig;
import org.compiere.model.MTable;
import org.compiere.model.MUser;
import org.compiere.model.SystemIDs;
import org.compiere.process.SvrProcess;
import org.compiere.util.CLogger;
import org.compiere.util.CacheMgt;
import org.compiere.util.Env;
import org.compiere.util.Trx;

public class zibraHashPasswords extends SvrProcess
{
	// Define latch for waiting to process till the completion of process
	CountDownLatch			latch;
	// Define How many thread wants to serve the service		
	private int				p_No_Of_Thread	= 8;
	// Taking for counting how many records are proceed
	AtomicInteger			count			= new AtomicInteger(0);
	// Taking for making batches of commit
	volatile AtomicInteger	batchcnt		= new AtomicInteger(0);

	protected CLogger		log				= CLogger.getCLogger(getClass());

	/**
	 * Prepare - e.g., get Parameters.
	 */
	protected void prepare()	
	{
	} // prepare	

	/**
	 * Perform process.
	 * 
	 * @return Message
	 * @throws Exception if not successful
	 */
	protected String doIt() throws Exception
	{
		boolean hash_password = MSysConfig.getBooleanValue(MSysConfig.USER_PASSWORD_HASH, false);

		if (hash_password)
			throw new AdempiereException("Passwords already hashed");

		String where = " Password IS NOT NULL AND Salt IS NULL  ";

		// update the sysconfig key to Y out of trx and reset the cache
		MSysConfig conf = new MSysConfig(getCtx(), SystemIDs.SYSCONFIG_USER_HASH_PASSWORD, null);
		conf.setValue("Y");
		conf.saveEx();
		CacheMgt.get().reset(MSysConfig.Table_Name);

		try
		{
			int[] userIDs = MTable.get(getCtx(), MUser.Table_ID).createQuery(where, get_TrxName()).getIDs();
			// Initialize latch size for thread waiting.
			latch = new CountDownLatch(userIDs.length);
			ExecutorService executor = Executors.newFixedThreadPool(p_No_Of_Thread);
			for (int userId : userIDs)
			{
				Runnable worker = new WorkerThreadForHashProcess(userId, this);
				executor.execute(worker);
			}
			try
			{
				latch.await();
			}
			catch (InterruptedException e)
			{
				log.saveError("Error while password hashes ", e.getMessage());
				throw new AdempiereException(e);
			}
			finally
			{
				executor.shutdown();
			}
		}
		catch (Exception e)
		{
			// reset to N on exception
			conf.setValue("N");
			conf.saveEx();
			CacheMgt.get().reset(MSysConfig.Table_Name);
			throw e;
		}
		return "@Updated@ " + count;
	} // doIt
}

/**
 * Create thread for serving hashpassword to user object
 * 
 * @author LOGILITE
 */
class WorkerThreadForHashProcess implements Runnable
{

	int					userID;
	zibraHashPasswords	zibraHashPass;

	public WorkerThreadForHashProcess(int userID, zibraHashPasswords zibraHashPass)
	{
		this.userID = userID;
		this.zibraHashPass = zibraHashPass;
	}

	@Override
	public void run()
	{
		String trxName = Trx.createTrxName(Thread.currentThread().getName().replaceAll("-", "_"));
		Trx currentTrx = Trx.get(trxName, true);
		MUser user = (MUser) MTable.get(Env.getCtx(), MUser.Table_ID).getPO(userID, trxName);
		try
		{
			user.setPassword(user.getPassword());
			zibraHashPass.count.getAndIncrement();
			zibraHashPass.batchcnt.getAndIncrement();
			user.saveEx();
			currentTrx.commit();
		}
		catch (Exception e)
		{
			System.out.println(e.getMessage());
			zibraHashPass.log.log(Level.SEVERE, e.getMessage());
			currentTrx.rollback();
		}
		finally
		{
			currentTrx.close();
		}
		zibraHashPass.latch.countDown();
	}
}
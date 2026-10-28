import os
import sys
import uuid
from datetime import datetime, timezone
import mysql.connector

# Ensure utf-8 output on Windows
sys.stdout.reconfigure(encoding='utf-8')

def get_env_credentials():
    env_path = os.path.join(os.path.dirname(__file__), '..', '.env')
    if not os.path.exists(env_path):
        env_path = os.path.join(os.getcwd(), 'SmartSpace_Backend', '.env')
    
    db_pass = ''
    if os.path.exists(env_path):
        with open(env_path, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if line.startswith('DB_PASSWORD='):
                    db_pass = line.split('=', 1)[1].strip()
    return db_pass

def run_migration():
    print("=" * 70)
    print(">> SMART SPACE - STAFF WALLET DATA MIGRATION SCRIPT")
    print("=" * 70)

    db_pass = get_env_credentials()
    conn = mysql.connector.connect(
        host='localhost',
        port=3306,
        user='root',
        password=db_pass,
        database='smart_space'
    )
    cursor = conn.cursor(dictionary=True)

    # 1. Get or create Wallet Config
    cursor.execute("SELECT * FROM wallet_configs LIMIT 1")
    config = cursor.fetchone()
    if not config:
        config_id = str(uuid.uuid4())
        now = datetime.now()
        cursor.execute("""
            INSERT INTO wallet_configs 
            (id, created_at, updated_at, commission_low, commission_medium, commission_high, commission_critical, penalty_rate_1, penalty_rate_2, penalty_rate_3)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, (config_id, now, now, 2000.0, 5000.0, 7000.0, 10000.0, 20.0, 20.0, 60.0))
        conn.commit()
        cursor.execute("SELECT * FROM wallet_configs LIMIT 1")
        config = cursor.fetchone()
        print("[Config] Created default wallet config.")
    else:
        print("[Config] Found existing wallet config.")

    severity_commission = {
        'low': config['commission_low'] or 2000.0,
        'medium': config['commission_medium'] or 5000.0,
        'high': config['commission_high'] or 7000.0,
        'critical': config['commission_critical'] or 10000.0,
    }
    penalty_rates = [
        (config['penalty_rate_1'] or 20.0) / 100.0,
        (config['penalty_rate_2'] or 20.0) / 100.0,
        (config['penalty_rate_3'] or 60.0) / 100.0,
    ]

    # 2. Ensure all staff users have a record in staff_wallets
    cursor.execute("SELECT id, full_name, email FROM users WHERE role = 'staff'")
    staff_users = cursor.fetchall()
    print(f"\n[Staff Users] Found {len(staff_users)} staff users.")

    staff_wallet_map = {}
    for staff in staff_users:
        s_id = staff['id']
        cursor.execute("SELECT * FROM staff_wallets WHERE user_id = %s", (s_id,))
        wallet = cursor.fetchone()
        if not wallet:
            w_id = str(uuid.uuid4())
            now = datetime.now()
            cursor.execute("""
                INSERT INTO staff_wallets (id, created_at, updated_at, balance, user_id)
                VALUES (%s, %s, %s, %s, %s)
            """, (w_id, now, now, 0.0, s_id))
            conn.commit()
            cursor.execute("SELECT * FROM staff_wallets WHERE id = %s", (w_id,))
            wallet = cursor.fetchone()
            print(f"  + Created new wallet for staff {staff['full_name']} ({s_id}) -> wallet {w_id}")
        staff_wallet_map[s_id] = wallet

    # Also check if any report assigned staff is not in staff_wallet_map
    cursor.execute("SELECT DISTINCT assigned_staff_id FROM reports WHERE assigned_staff_id IS NOT NULL")
    assigned_staff_ids = [r['assigned_staff_id'] for r in cursor.fetchall()]
    for s_id in assigned_staff_ids:
        if s_id not in staff_wallet_map:
            cursor.execute("SELECT * FROM staff_wallets WHERE user_id = %s", (s_id,))
            wallet = cursor.fetchone()
            if not wallet:
                w_id = str(uuid.uuid4())
                now = datetime.now()
                cursor.execute("""
                    INSERT INTO staff_wallets (id, created_at, updated_at, balance, user_id)
                    VALUES (%s, %s, %s, %s, %s)
                """, (w_id, now, now, 0.0, s_id))
                conn.commit()
                cursor.execute("SELECT * FROM staff_wallets WHERE id = %s", (w_id,))
                wallet = cursor.fetchone()
                print(f"  + Created new wallet for assigned staff ID {s_id} -> wallet {w_id}")
            staff_wallet_map[s_id] = wallet

    # 3. Update existing processed reports with commission data
    cursor.execute("""
        SELECT id, title, severity, status, assigned_staff_id, is_review_resolved, rating,
               resolved_at, created_at, updated_at, base_commission, commission_awarded,
               rehandling_penalty_count, total_commission_deducted
        FROM reports
        WHERE status = 'processed'
    """)
    processed_reports = cursor.fetchall()
    print(f"\n[Processed Reports] Found {len(processed_reports)} processed reports.")

    updated_reports_count = 0
    for r in processed_reports:
        r_id = r['id']
        sev = (r['severity'] or 'low').lower()
        comm = severity_commission.get(sev, 2000.0)

        # Check penalty status
        penalty_count = r['rehandling_penalty_count'] or 0
        deducted = r['total_commission_deducted'] or 0.0

        if r['is_review_resolved'] == 0:
            if penalty_count == 0:
                penalty_count = 1
                deducted = comm * penalty_rates[0]
        
        cursor.execute("""
            UPDATE reports
            SET base_commission = %s,
                commission_awarded = 1,
                rehandling_penalty_count = %s,
                total_commission_deducted = %s
            WHERE id = %s
        """, (comm, penalty_count, deducted, r_id))
        updated_reports_count += 1
        print(f"  * Report {r_id}: severity={sev}, base_comm={comm:,.0f}đ, penalty_count={penalty_count}, deducted={deducted:,.0f}đ")

    conn.commit()
    print(f"-> Successfully updated {updated_reports_count} processed reports.")

    # 4. Generate wallet transactions for awarded reports
    cursor.execute("""
        SELECT id, title, severity, status, assigned_staff_id, is_review_resolved,
               resolved_at, created_at, updated_at, base_commission, commission_awarded,
               rehandling_penalty_count, total_commission_deducted
        FROM reports
        WHERE commission_awarded = 1 AND assigned_staff_id IS NOT NULL
    """)
    awarded_reports = cursor.fetchall()
    print(f"\n[Transactions] Checking transactions for {len(awarded_reports)} reports with commission...")

    created_tx_count = 0
    for r in awarded_reports:
        r_id = r['id']
        staff_id = r['assigned_staff_id']
        wallet = staff_wallet_map.get(staff_id)
        if not wallet:
            continue
        wallet_id = wallet['id']
        base_comm = r['base_commission'] or severity_commission.get((r['severity'] or 'low').lower(), 2000.0)
        tx_time = r['resolved_at'] or r['updated_at'] or r['created_at'] or datetime.now()

        # Check COMMISSION transaction
        cursor.execute("""
            SELECT id FROM staff_wallet_transactions
            WHERE report_id = %s AND type = 'COMMISSION'
        """, (r_id,))
        existing_comm_tx = cursor.fetchone()
        if not existing_comm_tx:
            tx_id = str(uuid.uuid4())
            cursor.execute("""
                INSERT INTO staff_wallet_transactions
                (id, created_at, updated_at, amount, balance_after, title_i18n_key, title_params, type, report_id, wallet_id)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, (tx_id, tx_time, tx_time, base_comm, 0.0, 'wallet.transaction.commission.title', None, 'COMMISSION', r_id, wallet_id))
            created_tx_count += 1
            print(f"  + Added COMMISSION tx: +{base_comm:,.0f}đ for staff {staff_id} (Report {r_id})")

        # Check PENALTY_DEDUCTION transactions
        penalty_count = r['rehandling_penalty_count'] or 0
        if penalty_count > 0:
            cursor.execute("""
                SELECT id FROM staff_wallet_transactions
                WHERE report_id = %s AND type = 'PENALTY_DEDUCTION'
            """, (r_id,))
            existing_penalties = cursor.fetchall()
            existing_count = len(existing_penalties)
            for turn_idx in range(existing_count, min(penalty_count, 3)):
                rate = penalty_rates[turn_idx]
                penalty_amount = base_comm * rate
                tx_id = str(uuid.uuid4())
                pen_time = r['updated_at'] or datetime.now()
                cursor.execute("""
                    INSERT INTO staff_wallet_transactions
                    (id, created_at, updated_at, amount, balance_after, title_i18n_key, title_params, type, report_id, wallet_id)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                """, (tx_id, pen_time, pen_time, penalty_amount, 0.0, 'wallet.transaction.penalty.title', None, 'PENALTY_DEDUCTION', r_id, wallet_id))
                created_tx_count += 1
                print(f"  - Added PENALTY tx (turn {turn_idx+1}): -{penalty_amount:,.0f}đ for staff {staff_id} (Report {r_id})")

    conn.commit()
    print(f"-> Created {created_tx_count} new wallet transactions.")

    # 5. Recompute running balance for each wallet
    print("\n[Ledger Rebalancing] Recomputing wallet balances...")
    for staff_id, wallet in staff_wallet_map.items():
        w_id = wallet['id']
        cursor.execute("""
            SELECT id, type, amount, created_at
            FROM staff_wallet_transactions
            WHERE wallet_id = %s
            ORDER BY created_at ASC, id ASC
        """, (w_id,))
        txs = cursor.fetchall()

        running_balance = 0.0
        for tx in txs:
            t_type = tx['type']
            amt = tx['amount']
            if t_type == 'COMMISSION':
                running_balance += amt
            elif t_type in ('PENALTY_DEDUCTION', 'WITHDRAWAL'):
                running_balance -= amt
            
            cursor.execute("""
                UPDATE staff_wallet_transactions
                SET balance_after = %s
                WHERE id = %s
            """, (running_balance, tx['id']))
        
        # Update wallet balance
        now = datetime.now()
        cursor.execute("""
            UPDATE staff_wallets
            SET balance = %s, updated_at = %s
            WHERE id = %s
        """, (running_balance, now, w_id))
        conn.commit()
        print(f"  * Staff {staff_id} (Wallet {w_id}): {len(txs)} transactions, Final Balance = {running_balance:,.0f}đ")

    print("\n" + "=" * 70)
    print(">> MIGRATION COMPLETED SUCCESSFULLY!")
    print("=" * 70)

    cursor.close()
    conn.close()

if __name__ == '__main__':
    run_migration()

CREATE OR REPLACE FUNCTION bid_winner_set(a_id INTEGER) RETURNS VOID LANGUAGE sql AS
$_$
-- a_id: ID тендера
-- функция рассчитывает победителей заданного тендера
-- и заполняет поля bid.is_winner и bid.win_amount

-- ...
	WITH w AS
		(
		SELECT id, product_id,
				CASE WHEN remainder >= amount THEN NULL ELSE remainder END AS amount
			FROM
					(SELECT b.id, b.product_id, b.amount,
							b.price >= tp.start_price AND (b.price - tp.start_price) % tp.bid_step = 0 AS correct,
							tp.amount - (sum(b.amount) OVER (PARTITION BY b.product_id ORDER BY b.price DESC, b.id) - b.amount) AS remainder
						FROM bid AS b
						JOIN tender_product AS tp ON b.tender_id = tp.id AND b.product_id = tp.product_id
							WHERE b.tender_id = a_id
					) AS sq
				WHERE correct AND remainder > 0
		)
	UPDATE bid AS b
		SET is_winner = true, win_amount = w.amount
			FROM w
				WHERE b.id = w.id AND b.product_id = w.product_id;
;
$_$;

